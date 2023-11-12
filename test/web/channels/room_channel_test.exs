defmodule Web.RoomChannelTest do
  use Web.ChannelCase
  alias BillBored.{Chat, User}

  setup do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
    %Chat.Room.Membership{room: %Chat.Room{} = room} = insert(:chat_room_membership, user: user)
    %Chat.Room.Administratorship{} = insert(:chat_room_administratorship, user: user, room: room)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

    %{user: user, room: room, socket: socket}
  end

  describe "join" do
    test "lobby", %{user: user, socket: socket, room: room} do
      %{room: no_last_message_room} = insert(:chat_room_membership, user: user)
      no_last_message_room = Repo.preload(no_last_message_room, [:members, :administrators])
      room = Repo.preload(room, [:members, :administrators])

      %Chat.Message{} =
        last_message =
        insert(:chat_message,
          user: user,
          room: room,
          message: "Hi",
          media_files: [build(:upload, owner: user, media_key: "some media key")]
        )

      {:ok, reply, _socket} = subscribe_and_join(socket, "chats:lobby", %{})

      room = %{
        room
        | last_message:
            last_message
            |> Map.take([:id, :message, :message_type, :user_id])
            |> Map.put(:media_file_keys, Enum.map(last_message.media_files, & &1.media_key))
      }

      assert reply == %{
               "rooms" =>
                 Enum.map([no_last_message_room, room], fn room ->
                   "room.json"
                   |> Web.RoomView.render(room: room)
                   |> Map.put("muted?", false)
                 end)
             }
    end
  end

  describe "chat room membership change" do
    import Plug.Conn
    import Phoenix.ConnTest, except: [connect: 2]
    alias Web.Router.Helpers, as: Routes

    test "notified about self join and leave" do
      %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      # will receive the messages on the "chats:lobby" channel
      {:ok, _reply, _socket} = subscribe_and_join(socket, "chats:lobby", %{})

      # creates a chat to which our join then will be pushed
      %Chat.Room{id: room_id} = insert(:chat_room, chat_type: "private-group-chat")

      # joines the chat room
      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header(
        "authorization",
        "Bearer #{insert(:auth_token, user: build(:user, is_superuser: true)).key}"
      )
      |> put(Routes.chat_path(conn, :add_member, room_id, user.id))
      |> response(200)

      assert_push("chats:joined", sent_chat_room)
      assert %{"id" => ^room_id} = sent_chat_room
    end
  end

  describe "dropchat privilege request" do
    import Plug.Conn
    import Phoenix.ConnTest, except: [connect: 2]
    alias Web.Router.Helpers, as: Routes

    test "chats:privilege:request" do
      %User.AuthToken{user: %User{} = admin, key: token} = insert(:auth_token)
      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      # will receive the messages on the "chats:lobby" channel
      {:ok, _reply, _socket} = subscribe_and_join(socket, "chats:lobby", %{})

      # creates a dropchat
      %Chat.Room{id: room_id} =
        dropchat =
        insert(
          :chat_room,
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          private: false,
          reach_area_radius: 10
        )

      # makes our user an admin
      %Chat.Room.Administratorship{} =
        _administratorship = insert(:chat_room_administratorship, room: dropchat, user: admin)

      # creates an elevated privilege request into the dropchat
      requester = insert(:user)

      assert {:reply, :ok, _socket} =
               Web.DropchatChannel.handle_in(
                 "priveleges:update",
                 %{"request" => "write"},
                 socket(Web.UserSocket, "requester_socket", %{user: requester, room: dropchat})
               )

      request =
        Repo.get_by!(Chat.Room.ElevatedPrivilege.Request,
          room_id: dropchat.id,
          userprofile_id: requester.id
        )

      assert_push("chats:privilege:request", payload)

      assert payload == %{
               "id" => request.id,
               "room" => %{"id" => room_id},
               "user" => Web.UserView.render("user.json", %{user: requester})
             }
    end

    test "chats:privilege:granted" do
      %User.AuthToken{user: %User{} = requester, key: token} = insert(:auth_token)
      %User.AuthToken{user: %User{} = admin, key: admin_token} = insert(:auth_token)
      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      # will receive the messages on the "chats:lobby" channel
      {:ok, _reply, _socket} = subscribe_and_join(socket, "chats:lobby", %{})

      # creates a dropchat where our request went (as if)
      %Chat.Room{id: room_id} =
        dropchat =
        insert(
          :chat_room,
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          private: false,
          reach_area_radius: 10
        )

      # creates an elevated privilege for our user
      request = insert(:chat_room_elevated_privileges_request, user: requester, room: dropchat)

      insert(:chat_room_administratorship, room: dropchat, user: admin)
      conn = Phoenix.ConnTest.build_conn()

      assert %{"granted_privilege" => %{"id" => _id}} =
               conn
               |> put_req_header("authorization", "Bearer #{admin_token}")
               |> post(Routes.dropchat_path(conn, :grant_request), %{"request_id" => request.id})
               |> json_response(200)

      assert_push("chats:privilege:granted", payload)

      assert payload == %{"room_id" => room_id}
    end
  end
end
