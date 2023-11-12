defmodule Web.ChatController do
  use Web, :controller

  import BillBored.ServiceRegistry, only: [service: 1]

  alias BillBored.{Chat, User, Users, UserPoints, LocationRewards}
  alias BillBored.Chat.Room.DropchatBans

  action_fallback Web.FallbackController

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def chat_search(conn, params, user_id) do
    import Ecto.Query

    users = Map.get(params, "users")
    chat_types = Map.get(params, "chat_types")
    query = Chat.Rooms.get_available_rooms(user_id)

    query =
      if chat_types do
        where(query, [r, m], r.chat_type in ^chat_types)
      else
        query
      end

    query =
      if users do
        join(query, :left, [r, m], m2 in assoc(r, :participants))
        |> where([..., m2], m2.username in ^users)
      else
        query
      end

    render(conn, "chat_search.json", %{rooms: Repo.all(query)})
  end

  @list_rooms_params [
    {"chat_types", :chat_types, true, :string}
  ]

  def index(conn, params, user_id) do
    with {:ok, valid_params} <- validate_params(@list_rooms_params, params) do
      types = case valid_params.chat_types do
        "all" -> ["dropchat", "one-to-one", "private-group-chat"]
        "private" -> ["one-to-one", "private-group-chat"]
        "dropchat" -> ["dropchat"]
      end

      rooms = Chat.Rooms.list(for: user_id, chat_types: types)

      render(conn, "index.json", %{rooms: rooms})
    end
  end

  def create(conn, %{title: _} = attrs, current_user_id) do
    opts = if attrs[:add_users] do
      [add_members: attrs[:add_users]]
    else
      []
    end

    case Chat.Rooms.create(current_user_id, attrs, opts) do
      {:ok, room} ->
        room =
          Repo.preload(room, [
            :participants,
            :members,
            :moderators,
            :administrators,
            :interests,
            :pending,
            :interest,
            place: :types
          ])

        if room.chat_type == "dropchat" do
          admin_user = BillBored.Users.get!(current_user_id)

          BillBored.Users.top_followers(current_user_id, 5000)
          |> Enum.chunk_every(1_000)
          |> Enum.each(fn receivers ->
            receivers = receivers |> Repo.preload(:devices)
            service(Notifications).process_dropchat_created(admin_user, room, receivers)
          end)
        end

        broadcast_created_chat_room(room)
        broadcast_joining_chat_room_members(room)
        render(conn, "room.json", %{chat: room})

      {:error, %{duplicated_chat: room}} ->
        room =
          Repo.preload(room, [
            :participants,
            :members,
            :moderators,
            :administrators,
            :interests,
            :pending,
            :interest,
            place: :types
          ])

        render(conn, "room.json", %{chat: room})
      error -> error
    end
  end

  def create(conn, %{"One-to-one" => true} = attrs, current_user_id) do
    create(conn, %{attrs | "one-to-one" => true}, current_user_id)
  end

  def create(conn, %{"one-to-one" => true, "add_users" => [user_id]} = attrs, current_user_id) do
    unless Users.get(user_id) do
      {:ok, resp} = Jason.encode(%{errors: %{"add_users" => "user is missing"}})
      send_resp(conn, 400, resp)
    else
      attrs = %{
        color: attrs["color"] || "",
        title: "One to One",
        private: true,
        chat_type: "one-to-one",
        last_interaction: DateTime.utc_now(),
        add_users: [user_id]
      }

      create(conn, attrs, current_user_id)
    end
  end

  # create default mentor's private group chat
  def create(conn, %{"key" => <<"team_group_", str_mentor_id::binary>> = room_key} = attrs, current_user_id) do
    room = Chat.Rooms.get_by(key: room_key)
    mentor_id = String.to_integer(str_mentor_id)

    if is_nil(room) do
      mentee_ids = Users.Mentors.list_mentee_ids(mentor_id)

      attrs = %{
        key: room_key,
        color: "",
        title: attrs["title"],
        private: true,
        chat_type: "private-group-chat",
        last_interaction: DateTime.utc_now(),
        add_users: mentee_ids
      }

      create(conn, attrs, mentor_id)
    else
      with {:ok, role} <- validate_member_role(room, attrs["role"] || "member"),
           {:ok, membership} = Chat.Room.Memberships.create(current_user_id, room.id, role) do

        room =
          Repo.preload(room, [
            :participants,
            :members,
            :moderators,
            :administrators,
            :interests,
            :pending,
            :interest,
            place: :types
          ])

        broadcast_joining_chat_room_member(%{membership | room: room})
        render(conn, "room.json", %{chat: room})
      end
    end
  end

  def create(conn, %{"add_users" => user_ids} = attrs, current_user_id)
      when length(user_ids) <= 200 do
    {user_ids, missing} = Enum.split_with(user_ids, &Users.get/1)

    unless missing == [] do
      err_msg = "users #{inspect(missing)} are missing"
      {:ok, resp} = Jason.encode(%{errors: %{"add_users" => err_msg}})
      send_resp(conn, 400, resp)
    else
      attrs = %{
        color: attrs["color"] || "",
        title: attrs["title"],
        private: true,
        chat_type: "private-group-chat",
        last_interaction: DateTime.utc_now(),
        add_users: user_ids
      }

      create(conn, attrs, current_user_id)
    end
  end

  def create(conn, %{"location" => [lat, lng]} = attrs, current_user_id) do
    attrs = %{
      color: attrs["color"] || "",
      title: attrs["title"],
      chat_type: "dropchat",
      private: false,
      last_interaction: DateTime.utc_now(),
      location: %BillBored.Geo.Point{lat: lat, long: lng},
      # TODO verify required
      reach_area_radius: Map.fetch!(attrs, "reach_area_radius"),
      fake_location?: !!attrs["fake_location?"]
    }

    rewards = LocationRewards.get_nearest_location_rewards(attrs.location)
    UserPoints.give_location_points(current_user_id, rewards)

    create(conn, attrs, current_user_id)
  end

  def create(conn, %{"location" => %{"coordinates" => [lat, lng]}} = attrs, current_user_id) do
    attrs = %{
      color: attrs["color"] || "",
      title: attrs["title"],
      chat_type: "dropchat",
      private: false,
      last_interaction: DateTime.utc_now(),
      location: %BillBored.Geo.Point{lat: lat, long: lng},
      reach_area_radius: Map.fetch!(attrs, "reach_area_radius"),
      fake_location?: !!attrs["fake_location?"]
    }

    rewards = LocationRewards.get_nearest_location_rewards(attrs.location)
    UserPoints.give_location_points(current_user_id, rewards)

    create(conn, attrs, current_user_id)
  end

  # TODO move to Web.DropchatChannel.broadcast_new(dropchat)
  defp broadcast_created_chat_room(%Chat.Room{location: location, private: false} = dropchat)
       when not is_nil(location) do
    # TODO check dropchat.chat_type == "dropchat" as well?
    dropchat_reach_area_radius = Decimal.to_float(dropchat.reach_area_radius) * 1000

    message = %{
      location: dropchat.location,
      dropchat_reach_area_radius: dropchat_reach_area_radius,
      payload: %{"dropchat" => Web.RoomView.render("dropchat.json", %{room: dropchat})}
    }

    Web.Endpoint.broadcast("dropchats", "dropchat:new", message)
  end

  defp broadcast_created_chat_room(_room) do
    :ok
  end

  def delete(conn, %{"id" => room_id}, current_user_id) do
    room_id = String.to_integer(room_id)

    current_user = Users.get(current_user_id)
    room = Chat.Rooms.get(room_id)

    unless room do
      send_resp(conn, 204, [])
    else
      if Chat.Rooms.admin?(room, current_user) || current_user.is_superuser do
        Chat.Rooms.delete(room)

        send_resp(conn, 204, [])
      else
        send_resp(conn, 403, [])
      end
    end
  end

  def delete_member(conn, %{"id" => room_id, "user_id" => user_id}, current_user_id) do
    current_user = Users.get!(current_user_id)
    room = Chat.Rooms.get!(room_id)

    if current_user.is_superuser || Chat.Rooms.admin?(room, current_user) do
      membership = Chat.Room.Memberships.get_by(user_id: user_id, room_id: room.id)
      if membership, do: Repo.delete(membership)

      is_dropchat = room.chat_type == "dropchat"

      if is_dropchat do
        with %User{} = user <- Users.get(user_id) do
          DropchatBans.create(room, current_user, user)
        end
      end

      if membership || is_dropchat do
        broadcast_leaving_chat_room_member(room_id, user_id)
      end

      send_resp(conn, 204, [])
    else
      send_resp(conn, 403, [])
    end
  end

  def add_member(conn, %{"id" => room_id, "user_id" => user_id} = params, current_user_id) do
    current_user = Users.get!(current_user_id)
    room = Chat.Rooms.get!(room_id)

    with true <- current_user.is_superuser || Chat.Rooms.admin?(room, current_user),
         {:ok, role} <- validate_member_role(room, params["role"] || "member") do
      {:ok, membership} = Chat.Room.Memberships.create(String.to_integer(user_id), room.id, role)
      broadcast_joining_chat_room_member(%{membership | room: room})
      send_resp(conn, 200, [])
    else
      _ ->
        send_resp(conn, 403, [])
    end
  end

  defp validate_member_role(%Chat.Room{chat_type: "one-to-one"}, _), do: {:error, :invalid_role}
  defp validate_member_role(%Chat.Room{chat_type: "dropchat"}, "moderator"), do: {:ok, "moderator"}
  defp validate_member_role(%Chat.Room{chat_type: _}, "member"), do: {:ok, "member"}
  defp validate_member_role(%Chat.Room{chat_type: _}, _), do: {:error, :invalid_role}

  # TODO move to channel for easier discovery
  defp broadcast_joining_chat_room_member(%Chat.Room.Membership{
         userprofile_id: user_id,
         room: %Chat.Room{} = room
       }) do
    room = Chat.Rooms.preload_room(room, [:members, :moderators, :administrators, place: :types])
    Web.Endpoint.broadcast("rooms:#{user_id}", "join", %{room: room})
  end

  defp broadcast_joining_chat_room_members(%Chat.Room{participants: users} = room) do
    Enum.each(users, fn %{id: user_id} ->
      Web.Endpoint.broadcast("rooms:#{user_id}", "join", %{room: room})
    end)
  end

  # TODO test, move to channel for easier discovery
  defp broadcast_leaving_chat_room_member(room_id, user_id) do
    Web.Endpoint.broadcast("rooms:#{user_id}", "leave", %{room_id: room_id})
  end

  # TODO test
  def mute(conn, %{"key" => room_key}, current_user_id) do
    room = Chat.Rooms.get_by!(key: room_key)
    Chat.Rooms.mute_room(%{room_id: room.id, user_id: current_user_id})
    send_resp(conn, 200, [])
  end

  # TODO test
  def unmute(conn, %{"key" => room_key}, current_user_id) do
    room = Chat.Rooms.get_by!(key: room_key)
    Chat.Rooms.unmute_room(%{room_id: room.id, user_id: current_user_id})
    send_resp(conn, 200, [])
  end
end
