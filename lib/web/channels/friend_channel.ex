defmodule Web.FriendChannel do
  use Web, :channel
  alias BillBored.{User, Users}

  # TODO maybe use presence

  def join("friends", _params, %{assigns: %{user: %User{id: user_id}}} = socket) do
    Web.Endpoint.subscribe("friends:#{user_id}")

    user_id
    |> Users.list_friend_ids()
    |> Enum.each(fn friend_id ->
      Web.Endpoint.broadcast("friends:#{friend_id}", "online", %{user_id: user_id})
    end)

    {:ok, socket}
  end

  def terminate(_reason, %{assigns: %{user: %User{id: user_id}}}) do
    # friendships might change while the user is online
    # so we fetch the friend ids again

    user_id
    |> Users.list_friend_ids()
    |> Enum.each(fn friend_id ->
      Web.Endpoint.broadcast("friends:#{friend_id}", "offline", %{user_id: user_id})
    end)

    :ok
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "online",
          payload: %{user_id: user_id},
          topic: "friends:" <> _user_id
        },
        socket
      ) do
    push(socket, "friend:online", %{"user_id" => user_id})
    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "offline",
          payload: %{user_id: user_id},
          topic: "friends:" <> _user_id
        },
        socket
      ) do
    push(socket, "friend:offline", %{"user_id" => user_id})
    {:noreply, socket}
  end
end
