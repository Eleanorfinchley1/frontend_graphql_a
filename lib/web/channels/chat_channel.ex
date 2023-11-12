defmodule Web.ChatChannel do
  use Web, :channel
  alias BillBored.{Chat, User}

  def join("chats:" <> room_id, _params, %{assigns: %{user: %User{id: user_id}}} = socket) do
    room =
      case Integer.parse(room_id) do
        {id, ""} ->
          Chat.Rooms.get(id)

        _ ->
          # String-type id was given:
          Chat.Rooms.get_by(key: room_id)
      end

    if room do
      case Chat.Room.Memberships.get_by(user_id: user_id, room_id: room.id) do
        %Chat.Room.Membership{room_id: room_id} ->
          send(self(), :after_join)

          room = Chat.Rooms.get(room_id)

          # TODO maybe assign the loaded room and not just id to the channel
          rendered_administrators =
            room_id
            |> Chat.Rooms.list_administrators()
            |> Phoenix.View.render_many(Web.UserView, "user.json")

          new_socket =
            socket
            |> assign(:room, room)
            |> maybe_assign_ignore_set()

          Phoenix.PubSub.subscribe(Web.PubSub, "user_blocks:#{user_id}")

          {:ok, %{"administrators" => rendered_administrators}, new_socket}

        nil ->
          {:error, %{"detail" => "user is not a member of the #{room.key} chat"}}
      end
    else
      {:error, %{"detail" => "chat with key/id #{room_id} does not exist"}}
    end
  end

  ## NEW MESSAGE

  ## TODO refactor

  def handle_in(
        "message:new",
        %{"forward" => %{"id" => forwarded_message_id}},
        %{assigns: %{user: user, room: room}} = socket
      ) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    case Chat.Messages.forward(forwarded_message_id, %{room: room, user: user}) do
      {:ok, %Chat.Message{} = message} ->
        broadcast_from!(
          socket,
          "message:new",
          Web.MessageView.render("message.json", %{message: message, user: user})
        )

        {:reply, {:ok, Web.MessageView.render("created_message.json", %{message: message})},
         socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, BillBored.Helpers.humanize_errors(changeset)}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{"forwarded_message" => ["does not exist"]}}, socket}
    end
  end

  def handle_in(
        "message:new",
        %{"reply_to" => %{"id" => replied_to_message_id}} = attrs,
        %{assigns: %{user: user, room: room}} = socket
      ) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    case Chat.Messages.reply(attrs, %{to: replied_to_message_id, room: room, user: user}) do
      {:ok, %Chat.Message{} = message} ->
        broadcast_from!(
          socket,
          "message:new",
          Web.MessageView.render("message.json", %{message: message, user: user})
        )

        {:reply, {:ok, Web.MessageView.render("created_message.json", %{message: message})},
         socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, BillBored.Helpers.humanize_errors(changeset)}, socket}
    end
  end

  def handle_in("message:new", params, %{assigns: %{user: user, room: room}} = socket) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    case Chat.Messages.create(params, %{room: room, user: user}) do
      {:ok, %Chat.Message{} = message} ->
        broadcast_from!(
          socket,
          "message:new",
          Web.MessageView.render("message.json", %{message: message, user: user})
        )

        {:reply, {:ok, Web.MessageView.render("created_message.json", %{message: message})},
         socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        # TODO move to error helpers?
        {:reply, {:error, BillBored.Helpers.humanize_errors(changeset)}, socket}
    end
  end

  ## MESSAGE FETCH

  # TODO refactor
  def handle_in(
        "messages:fetch",
        params,
        %{assigns: %{user: %User{id: user_id} = user, room: %{id: room_id}}} = socket
      ) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    {fetch_direction, message_id} =
      case params do
        %{"after" => %{"id" => message_id}} -> {:after, message_id}
        %{"before" => %{"id" => message_id}} -> {:before, message_id}
      end

    order =
      case params["order"] do
        "desc" -> :desc
        _other -> :asc
      end

    messages =
      if limit = params["limit"] do
        Chat.Messages.fetch(room_id, fetch_direction, message_id, %{
          limit: limit,
          order: order,
          for_id: user_id
        })
      else
        Chat.Messages.fetch(room_id, fetch_direction, message_id, %{order: order, for_id: user_id})
      end

    {:reply,
     {:ok, %{"messages" => Web.MessageView.render("messages.json", %{messages: messages})}},
     socket}
  end

  ## CHAT READ

  def handle_in(
        "chat:read",
        _params,
        %{assigns: %{user: %User{} = user, room: %Chat.Room{} = room}} = socket
      ) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    Chat.Messages.mark_read(room, user)
    broadcast_from!(socket, "chat:read", %{})
    {:reply, :ok, socket}
  end

  ## TYPING

  def handle_in(
        "user:typing",
        %{"typing" => typing?},
        %{assigns: %{user: %User{id: user_id, username: username} = user}} = socket
      ) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    {:ok, _ref} = Web.Presence.update(socket, user_id, %{typing: typing?, username: username})

    {:reply, :ok, socket}
  end

  ## PRESENCE

  def handle_info(
        :after_join,
        %{assigns: %{user: %User{id: user_id, username: username}}} = socket
      ) do
    push(socket, "presence_state", Web.Presence.list(socket))

    {:ok, _ref} =
      Web.Presence.track(socket, user_id, %{
        typing: false,
        username: username
      })

    {:noreply, socket}
  end

  def handle_info(
        {:user_blocks_update, %{id: user_id}},
        %{assigns: %{user: %User{id: user_id}}} = socket
      ) do
    {:noreply, maybe_assign_ignore_set(socket)}
  end

  intercept(["message:new"])

  def handle_out(
        "message:new" = event,
        %{user: %User{id: sender_user_id}} = payload,
        %{assigns: %{ignore_set: ignore_set}} = socket
      ) do
    if MapSet.member?(ignore_set, sender_user_id) do
      {:noreply, socket}
    else
      push(socket, event, payload)
      {:noreply, socket}
    end
  end

  def handle_out("message:new" = event, payload, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  defp maybe_assign_ignore_set(%{assigns: %{user: user}} = socket) do
    blockers_ids = BillBored.User.Blocks.get_blockers_of(user) |> Enum.map(& &1.id)
    blocked_ids = BillBored.User.Blocks.get_blocked_by(user) |> Enum.map(& &1.id)

    ignore_set = MapSet.new(blocked_ids ++ blockers_ids)

    case MapSet.size(ignore_set) do
      0 ->
        %{socket | assigns: Map.delete(socket.assigns, :ignore_set)}

      _ ->
        assign(socket, :ignore_set, ignore_set)
    end
  end
end
