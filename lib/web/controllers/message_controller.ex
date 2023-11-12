defmodule Web.MessageController do
  use Web, :controller

  import Ecto.Query
  alias BillBored.Chat.{Message, Messages, Room}

  # action_fallback(Web.FallbackController)

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def index(conn, params, user_id) do
    page = Map.get(params, "page", 0)
    search = params["search"]
    query = get_messages(user_id)

    data =
      if search do
        room_ids =
          Room
          |> where([r], ilike(r.key, ^search))
          |> select([r], r.id)
          |> Repo.all()

        query
        |> where([m], m.room_id in ^room_ids)
      else
        query
      end
      |> limit(20)
      |> offset(^(page * 20))
      |> Repo.all()

    render(conn, "index.json", %{messages: data})
  end

  def show(conn, %{"id" => id} = params, user_id) do
    search = params["search"]
    query = get_messages(user_id)

    data =
      if search do
        room_ids =
          Room
          |> where([r], ilike(r.key, ^search))
          |> select([r], r.id)
          |> Repo.all()

        query
        |> where([m], m.room_id in ^room_ids)
      else
        query
      end
      |> where([m], m.id == ^id)
      |> Repo.one()

    render(conn, "show.json", %{message: data})
  end

  def create(conn, %{"room" => room_id} = params, user_id) do
    Messages.create(params, room_id: room_id, user_id: user_id)
    |> case do
      {:ok, message} ->
        render(conn, "created_message.json", %{message: message})

      {:error, _} ->
        send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))
    end
  end

  def update(conn, %{"id" => id} = params, _user_id) do
    Message
    |> Repo.get_by(id: id)
    |> case do
      nil ->
        send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))

      message ->
        message
        |> Message.changeset(params)
        |> Repo.update()
        |> case do
          {:ok, message} ->
            data =
              Repo.preload(message, [
                :forwarded_message,
                :replied_to,
                :user,
                :private_post,
                :room,
                :hashtags_interest,
                :usertags,
                :users_seen_message
              ])

            render(conn, "show.json", %{message: data})

          {:error, _} ->
            send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))
        end
    end
  end

  def delete(conn, %{"id" => id}, user_id) do
    Message
    |> Repo.get_by(id: id)
    |> case do
      %Message{} = message ->
        if message.user_id == user_id do
          Repo.delete(message)
        end

        send_resp(conn, :ok, [])

      _ ->
        send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))
    end
  end

  defp get_messages(user_id) do
    room_ids =
      Room.Membership
      |> where([rm], rm.userprofile_id == ^user_id)
      |> select([rm], rm.room_id)
      |> Repo.all()

    Message
    |> where([m], m.room_id in ^room_ids)
    |> preload([
      :forwarded_message,
      :replied_to,
      :user,
      :private_post,
      :room,
      :hashtags_interest,
      :usertags,
      :users_seen_message
    ])
  end
end
