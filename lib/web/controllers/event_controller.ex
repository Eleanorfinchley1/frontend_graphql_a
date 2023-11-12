defmodule Web.EventController do
  use Web, :controller
  alias BillBored.{Events, Event, Posts, Users}
  import BillBored.Helpers, only: [decode_base64_id: 2]

  action_fallback Web.FallbackController

  defp current_user_id!(%Plug.Conn{assigns: assigns}) do
    Map.fetch!(assigns, :user_id)
  end

  def create(conn, %{"id" => post_id} = attrs) do
    post = Posts.get!(post_id)
    post = Repo.preload(post, [:author])
    user = Users.get(current_user_id!(conn))
    if post.author.id == user.id || user.is_superuser do
      attrs = Map.put(attrs, "post_id", post_id)

      with {:ok, event} <- Events.create(attrs) do
        render_result(conn, Web.EventView.render("show.json", event: event))
      end
    else
      send_resp(conn, 403, [])
    end
  end

  def show(conn, %{"id" => event_id}) do
    # TODO simplify, don't hardcode path info
    {template, event} =
      case conn.path_info do
        ["api" | _rest] ->
          user = Users.get(current_user_id!(conn))
          {"show.json", Events.get!(event_id, for_id: if(user.is_superuser == true, do: nil, else: user.id))}

        ["events" | _rest] ->
          {"show.html",
           event_id
           |> decode_base64_id(%{schema: Event})
           |> Events.get!()}
      end

    render(conn, template, event: event)
  end

  def delete(conn, %{"id" => event_id}) do
    event =
      event_id
      |> Events.get!()
      |> Repo.preload([:post])

    user = Users.get(current_user_id!(conn))
    if user.id == event.post.author_id || user.is_superuser do
      Events.delete(event.id)
      send_resp(conn, 204, [])
    else
      send_resp(conn, 403, [])
    end
  end

  def update(conn, %{"id" => event_id} = attrs) do
    old_event = Events.get!(String.to_integer(event_id)) |> Repo.preload([:post])

    user = Users.get(current_user_id!(conn))
    if user.id == old_event.post.author_id || user.is_superuser do
      with {:ok, event} <- Events.update(old_event, attrs) do
        render_result(conn, Web.EventView.render("show.json", event: event))
      end
    else
      send_resp(conn, 403, [])
    end
  end

  def attend(conn, %{"id" => event_id}) do
    set_status(conn, %{"id" => event_id, "status" => "accepted"})
  end

  def refuse(conn, %{"id" => event_id}) do
    set_status(conn, %{"id" => event_id, "status" => "refused"})
  end

  def invite(conn, %{"id" => event_id, "user_id" => user_id}) do
    event = Repo.get!(Event, event_id) |> Repo.preload([:post])

    user = Users.get(current_user_id!(conn))
    if event.post.author_id == user.id || user.is_superuser do
      case Events.set_status(event, for_id: String.to_integer(user_id), to: "invited") do
        {:ok, _} ->
          send_resp(conn, 204, [])

        {:error, :past} ->
          conn
          |> put_status(400)
          |> json(%{success: false, reason: "The event is already passed!"})

        other ->
          other
      end
    else
      send_resp(conn, 403, [])
    end
  end

  def set_status(conn, %{"id" => event_id, "status" => status}) do
    event = Repo.get!(Event, event_id)

    case Events.set_status(event, for_id: current_user_id!(conn), to: status) do
      {:ok, _att} ->
        send_resp(conn, 204, [])

      {:error, :future} ->
        conn
        |> put_status(400)
        |> json(%{success: false, reason: "The event is not yet started!"})

      {:error, :past} ->
        conn
        |> put_status(400)
        |> json(%{success: false, reason: "The event is already passed!"})

      # TODO :incorrent????
      {:error, :incorrent} ->
        statuses = Event.Attendant.statuses()

        reason = """
        The status #{status} is incorrect.
        Use one of the #{inspect(statuses.future)} or #{inspect(statuses.past)}.
        """

        conn
        |> put_status(400)
        |> json(%{success: false, reason: reason})

      other ->
        other
    end
  end
end
