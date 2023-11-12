defmodule Web.PostController do
  use Web, :controller
  alias BillBored.{Post, Posts, Users}
  import BillBored.Helpers, only: [humanize_errors: 1, decode_base64_id: 2]
  import BillBored.ServiceRegistry, only: [service: 1]

  require Logger

  action_fallback Web.FallbackController

  defp current_user_id!(%Plug.Conn{assigns: assigns}) do
    Map.fetch!(assigns, :user_id)
  end

  def index(conn, %{"id" => _author_id, "type" => "vote-post"} = params) do
    index(conn, Map.put(params, "type", "vote"))
  end

  @types ["vote", "poll", "event", "regular"]
  def index(conn, %{"id" => _author_id, "type" => type} = params)
      when type not in @types do
    index(conn, Map.delete(params, "type"))
  end

  def index(conn, %{"id" => author_id, "type" => type} = params) do
    author_id = String.to_integer(author_id)
    posts = Posts.index(author_id, type, params)
    render(conn, "index.json", data: posts)
  end

  def index(conn, %{"id" => author_id} = params) do
    author_id = String.to_integer(author_id)
    posts = Posts.index(author_id, params)
    render(conn, "index.json", data: posts)
  end

  def index_for_user(conn, params) do
    params = Map.put(params, "id", to_string(current_user_id!(conn)))
    index(conn, params)
  end

  defp handle_vote("upvote", user, post) do
    Posts.upvote!(post, by: user)
  end

  defp handle_vote("downvote", user, post) do
    Posts.downvote!(post, by: user)
  end

  defp handle_vote("unvote", user, post) do
    Posts.unvote!(post, by: user)
  end

  def vote(conn, %{"id" => post_id, "action" => action}) do
    user = conn |> current_user_id!() |> Users.get_by_id()
    post = Posts.get!(post_id)
    handle_vote(action, user, post)
    send_resp(conn, 204, [])
  end

  def show(conn, %{"id" => post_id} = params) do
    # TODO simplify, don't hardcode path info
    {template, post} =
      case conn.path_info do
        ["api" | _rest] ->
          post = Posts.get!(post_id, for_id: current_user_id!(conn))
          track_post_view(post, current_user_id!(conn), params)
          {"show.json", post}

        ["posts" | _rest] ->
          {"show.html",
           post_id
           |> decode_base64_id(%{schema: Post})
           |> Posts.get!()}
      end

    render(conn, template, post: post)
  end

  defp track_post_view(post, user_id, params) do
    with user <- Users.get_by_id(user_id),
         {:ok, post_view} <- BillBored.Clickhouse.PostView.build(post, user, params) do
      service(BillBored.Clickhouse.PostViews).create(post_view)
    end
  end

  def create(conn, %{"type" => "event", "event_location" => event_location} = params) do
    event_params = Map.put(params, "location", event_location)

    params =
      params
      |> Map.delete("media_file_keys")
      |> Map.put("events", [event_params])

    do_create(conn, params)
  end

  def create(conn, params) do
    do_create(conn, params)
  end

  def do_create(conn, params) do
    user_id = current_user_id!(conn)
    params = Map.put(params, "author_id", user_id)

    case Posts.Policy.authorize(:create_post, params, user_id) do
      true ->
        create_post_and_send_response(conn, %Post{}, params)

      {false, "Approval required"} ->
        create_post_and_send_response(conn, %Post{approved?: false}, params)

      false ->
        conn
        |> put_status(403)
        |> json(%{success: false, reason: "Unauthorized to create post"})
    end
  end

  defp create_post_and_send_response(conn, post, params) do
    case Posts.insert_or_update(post, params) do
      {:ok, post} ->
        post =
          Repo.preload(post, [
            :media_files,
            :author,
            :admin_author,
            :business,
            :business_admin,
            :interests,
            place: :types,
            events: [:media_files, :attendees, place: :types],
            polls: [items: :media_files]
          ])

        rendered_post = Web.PostView.render("show.json", post: post)

        if post.approved? do
          broadcast_post(post, rendered_post)
          user_ids = BillBored.Users.search_user_ids_by_interests(post.interests)
          user_ids = user_ids ++ if(Map.has_key?(params, "follows_user"), do: params["follows_user"], else: [])
          user_ids = user_ids |> Enum.uniq()
          if length(user_ids) > 0 do
            send_push_notifications(user_ids, post)
          end
        end

        json(conn, %{
          success: true,
          result: rendered_post
        })

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{success: false, reason: humanize_errors(reason)})
    end
  end

  defp broadcast_post(post, rendered_post) do
    message = %{
      location: post.location,
      payload: %{"post" => rendered_post},
      post_type: String.to_atom(post.type),
      author: post.author
    }

    Web.Endpoint.broadcast("posts", "post:new", message)
    Web.Endpoint.broadcast("personalized", "post:new", message)
    if post.type == "offer", do: Web.Endpoint.broadcast("offers", "post:new", message)
  end

  def request_approval(conn, %{"post_id" => post_id, "approver_id" => approver_id}) do
    case Posts.request_business_post_approval(
           post_id,
           approver_id,
           _requester_id = current_user_id!(conn)
         ) do
      {:ok, _changes} ->
        json(conn, %{success: true})

      {:error, field, reason, _changes} ->
        conn
        |> put_status(422)
        |> json(%{success: false, reason: approval_error_reason(field, reason)})
    end
  end

  defp approval_error_reason(:post, reason) do
    case reason do
      :not_found -> "Post not found"
      :not_business_post -> "Post is not a business post"
      :already_approved -> "Post is already approved"
    end
  end

  defp approval_error_reason(:approver_membership, reason) do
    case reason do
      :not_found -> "Approver membership not found"
      :invalid_role -> "Invalid approver membership role"
    end
  end

  defp approval_error_reason(:ensure_new_request, :already_exists) do
    "Approval request already exists"
  end

  defp approval_error_reason(:request, :not_found) do
    "Approval request not found"
  end

  defp approval_error_reason(:rejection, %Ecto.Changeset{} = changeset) do
    humanize_errors(changeset)
  end

  def approve_post(conn, %{"post_id" => post_id, "requester_id" => requester_id}) do
    case Posts.approve_business_post(post_id, _approver_id = current_user_id!(conn), requester_id) do
      {:ok, %{approved_post: %Post{} = post}} ->
        post = Repo.preload(post, [:interests, :polls, :events, place: :types])
        broadcast_post(post, Web.PostView.render("show.json", post: post))
        json(conn, %{success: true})

      {:error, field, reason, _changes} ->
        conn
        |> put_status(422)
        |> json(%{success: false, reason: approval_error_reason(field, reason)})
    end
  end

  def reject_post(
        conn,
        %{"post_id" => post_id, "requester_id" => requester_id, "note" => note}
      ) do
    case Posts.reject_business_post(
           post_id,
           _approver_id = current_user_id!(conn),
           requester_id,
           note
         ) do
      {:ok, _changes} ->
        json(conn, %{success: true})

      {:error, field, reason, _changes} ->
        conn
        |> put_status(422)
        |> json(%{success: false, reason: approval_error_reason(field, reason)})
    end
  end

  def update(conn, %{"id" => id, "type" => "event", "event_location" => _} = params) do
    post = Posts.get!(id, for_id: current_user_id!(conn))

    case post.events do
      [_single_event] ->
        event =
          params
          |> Map.take(["date", "title", "media_file_keys"])
          |> Map.put("location", params["event_location"])

        params =
          params
          |> Map.delete("event_location")
          |> Map.delete("media_file_keys")
          |> Map.put("events", [event])

        update(conn, params)

      _ ->
        conn
        |> put_status(400)
        |> json(%{
          success: false,
          reason: """
          Post #{id} has more than one events being attached.
          You cannot use old-type API to update it with event.
          """
        })
    end
  end

  def update(conn, %{"id" => post_id} = attrs) do
    user_id = current_user_id!(conn)
    old_post = Posts.get!(post_id, for_id: user_id) |> Repo.preload(:business_offer)

    case Posts.Policy.authorize(:update_post, old_post, user_id) do
      true ->
        with {:ok, _new_post} <- Posts.update(old_post, attrs) do
          new_post = Posts.get!(post_id, for_id: user_id)

          old_json = Web.PostView.render("show.json", post: old_post)
          new_json = Web.PostView.render("show.json", post: new_post)

          fields =
            for field <- Map.keys(old_json), old_json[field] != new_json[field] do
              if is_list(old_json[field]) do
                on = old_json[field] -- new_json[field]
                no = new_json[field] -- old_json[field]

                if on == no, do: []
              end || [field]
            end
            |> List.flatten()

          message = %{
            location: new_post.location,
            post_type: String.to_atom(new_post.type),
            author: new_post.author,
            payload: %{
              "id" => post_id,
              "changes" => Map.take(new_json, fields)
            }
          }

          Web.Endpoint.broadcast("posts", "post:update", message)
          Web.Endpoint.broadcast("personalized", "post:update", message)

          if new_post.type == "offer",
            do: Web.Endpoint.broadcast("offers", "post:update", message)

          json(conn, %{success: true, result: new_json})
        end

      {false, reason} ->
        Logger.debug("Can't update post: #{inspect(reason)}")
        send_resp(conn, 403, [])
    end
  end

  def delete(conn, %{"id" => post_id}) do
    post = Posts.get!(post_id)

    case Posts.Policy.authorize(:delete_post, post, current_user_id!(conn)) do
      true ->
        case Posts.delete(post.id) do
          {:ok, post} ->
            message = %{
              location: post.location,
              post_type: String.to_atom(post.type),
              author: post.author,
              payload: %{"id" => post.id}
            }

            Web.Endpoint.broadcast("posts", "post:delete", message)
            if post.type == "offer", do: Web.Endpoint.broadcast("offers", "post:delete", message)

          :error ->
            :error
        end

        send_resp(conn, 204, [])

      {false, reason} ->
        Logger.debug("Can't delete post: #{inspect(reason)}")
        send_resp(conn, 403, [])
    end
  end

  def list_nearby(
        conn,
        %{"location" => geo, "radius" => radius, "precision" => precision} = params
      ) do
    with {:ok, filter} <- BillBored.Posts.Filter.parse(params["filter"] || %{}),
         filter <-
           Map.merge(filter, extract_params(params, ~w(page page_size types is_business)s)),
         filter <- Map.merge(filter, %{for_id: current_user_id!(conn)}),
         %Geo.Point{coordinates: {lat, lon}} <- Geo.JSON.decode!(geo),
         location <- %BillBored.Geo.Point{lat: lat, long: lon},
         %{entries: posts} = result <-
           Posts.list_by_geohash_at_location({location, radius}, precision, filter) do
      json(
        conn,
        Map.put(
          result,
          :entries,
          Phoenix.View.render_many(posts, Web.PostView, "show.json", conn.assigns)
        )
      )
    end
  end

  defp extract_params(params, keys) do
    Enum.reduce(keys, %{}, fn k, acc ->
      case params do
        %{^k => value} ->
          Map.put(acc, String.to_atom(k), value)

        _ ->
          acc
      end
    end)
  end

  def list_business_posts(conn, %{"id" => business_id} = params) do
    with filter <- extract_params(params, ~w(page page_size types include_unapproved)s),
         filter <- Map.merge(filter, %{for_id: current_user_id!(conn)}),
         {:ok, business_account} <- Users.get_business_account(id: business_id),
         %{entries: posts} = result <- Posts.list_by_business_account(business_account, filter) do
      json(
        conn,
        Map.put(
          result,
          :entries,
          Phoenix.View.render_many(posts, Web.PostView, "show.json", conn.assigns)
        )
      )
    end
  end

  defp send_push_notifications([], _post), do: nil

  defp send_push_notifications(receivers, post) when is_list(receivers) do
    BillBored.Users.all(receivers)
    |> Enum.chunk_every(1_000)
    |> Enum.each(fn receivers ->
      receivers = receivers |> Repo.preload(:devices)
      service(Notifications).process_post_push_notifications(receivers, post)
    end)
  end
end
