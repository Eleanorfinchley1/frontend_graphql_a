defmodule Web.RoomChannel do
  use Web, :channel
  alias BillBored.{User, Chat}

  def join("chats:lobby", _params, %{assigns: %{user: %User{id: user_id} = user}} = socket) do
    Web.Endpoint.subscribe("rooms:#{user_id}")
    rooms = Chat.Rooms.list(for: user)
    muted_room_ids = user.id |> Chat.Rooms.list_muted_room_ids() |> MapSet.new()

    rendered_rooms =
      Enum.map(rooms, fn room ->
        "room.json"
        |> Web.RoomView.render(%{room: room})
        |> Map.put("muted?", MapSet.member?(muted_room_ids, room.id))
      end)

    {:ok, %{"rooms" => rendered_rooms}, socket}
  end

  ## CHAT ROOM MEMBERSHIP

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "join",
          payload: %{room: %Chat.Room{} = room},
          topic: "rooms:" <> _user_id
        },
        socket
      ) do
    # TODO preload dropchat fields
    room = %{room | last_message: Chat.Rooms.last_message(room.id)}
    push(socket, "chats:joined", Web.RoomView.render("room.json", %{room: room}))
    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "leave",
          payload: %{room_id: room_id},
          topic: "rooms:" <> _user_id
        },
        socket
      ) do
    push(socket, "chats:left", %{"room_id" => room_id})
    {:noreply, socket}
  end

  ## DROPCHAT PRIVILEGE REQUEST

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "chats:privilege:request",
          payload: payload,
          topic: "rooms:" <> _user_id
        },
        socket
      ) do
    push(socket, "chats:privilege:request", payload)
    {:noreply, socket}
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "chats:privilege:granted",
          payload: payload,
          topic: "rooms:" <> _user_id
        },
        socket
      ) do
    push(socket, "chats:privilege:granted", payload)
    {:noreply, socket}
  end
end
