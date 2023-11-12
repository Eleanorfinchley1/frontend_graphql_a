defmodule Web.Torch.API.PostController do
  use Web, :controller
  alias BillBored.{Post, Posts}
  import BillBored.Helpers, only: [humanize_errors: 1]
  import BillBored.ServiceRegistry, only: [service: 1]

  plug Web.Plugs.TorchCheckPermissions, required_permission: [
    create: "post:create",
    update: "post:update",
    delete: "post:delete",
    show: "post:show",
    index: "post:list"
  ]

  def create(conn, %{"type" => _type} = params) do
    do_create(conn, params)
  end

  def create(conn, %{"event_location" => event_location} = params) do
    event_params = Map.merge(params, %{"location" => event_location, "type" => "event"})

    params =
      params
      |> Map.delete("media_file_keys")
      |> Map.merge(%{"type" => "event", "events" => [event_params]})

    do_create(conn, params)
  end

  defp do_create(%Plug.Conn{assigns: %{admin: admin}} = conn, params) do
    params = Map.put(params, "admin_author_id", admin.id)
    create_post_and_send_response(conn, %Post{}, params)
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

  def update(conn, %{"id" => id, "type" => "event", "event_location" => _} = params) do
    post = Posts.get!(id)

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

  def update(conn, %{"id" => id, "event_location" => _} = params) do
    params = Map.put(params, "type", "event")
    update(conn, params)
  end

  def update(conn, %{"id" => post_id} = attrs) do
    old_post = Posts.get!(post_id) |> Repo.preload(:business_offer)

    with {:ok, _new_post} <- Posts.update(old_post, attrs) do
      new_post = Posts.get!(post_id)

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
  end

  def show(conn, %{"id" => post_id} = params) do
    post = Posts.get!(post_id)

    rendered_post = Web.PostView.render("show.json", post: post)
    json(conn, %{
      success: true,
      result: rendered_post
    })
  end

  def delete(conn, %{"id" => post_id}) do
    case Posts.delete(post_id) do
      {:ok, post} ->
        message = %{
          location: post.location,
          post_type: String.to_atom(post.type),
          author: post.author || post.admin_author,
          payload: %{"id" => post.id}
        }

        Web.Endpoint.broadcast("posts", "post:delete", message)
        if post.type == "offer", do: Web.Endpoint.broadcast("offers", "post:delete", message)
      :error ->
        :error
    end

    send_resp(conn, 204, [])
  end

  @index_params [
    {"page", :page, false, :integer},
    {"page_size", :page_size, false, :integer},
    {"sort_direction", :sort_direction, false, :string},
    {"sort_field", :sort_field, false, :string},
    {"keyword", :keyword, false, :string},
    {"filter_type", :filter_type, false, :string},
    {"filter_approved", :filter_approved, false, :string}
  ]
  def index(conn, params) do
    {:ok, params} = validate_params(@index_params, params)

    page = Posts.paginate(params)
    rendered_post = Web.PostView.render("index.json", conn: conn, data: page)
    json(conn, rendered_post)
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
