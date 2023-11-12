defmodule Web.ChatControllerTest do
  use Web.ConnCase, async: true
  import BillBored.Factory

  import BillBored.ServiceRegistry, only: [replace: 2]

  alias BillBored.Chat.Room.Membership
  alias BillBored.Chat.Room.Memberships
  alias BillBored.Chat.Room.DropchatBans

  defmodule Stubs.Notifications do
    def process_dropchat_created(admin_user, room, receivers) do
      send(self(), {__MODULE__, :process_dropchat_created, {admin_user, room, receivers}})
      :ok
    end
  end

  describe "chat room" do
    setup [:create_users]

    test "can be created", %{conn: conn, tokens: [author, _ | _]} do
      params = %{
        "location" => [30.7008, 76.7885],
        "color" => "#FF006D",
        "reach_area_radius" => 20.0,
        "title" => "dropchat",
        "fake_location?" => false
      }

      conn
      |> authenticate(author)
      |> post(Routes.chat_path(conn, :create), params)
      |> response(200)
    end

    test "notifies followers when dropchat is created", %{conn: conn, tokens: [author, _ | _]} do
      params = %{
        "location" => [30.7008, 76.7885],
        "color" => "#FF006D",
        "reach_area_radius" => 20.0,
        "title" => "dropchat",
        "fake_location?" => false
      }

      following = insert(:user_following, to: author.user)
      insert(:user_device, user: following.from)

      replace(Notifications, Stubs.Notifications)

      assert %{
               "key" => room_key
             } =
               conn
               |> authenticate(author)
               |> post(Routes.chat_path(conn, :create), params)
               |> json_response(200)

      assert_received {Stubs.Notifications, :process_dropchat_created,
                       {admin_user, room, [receiver]}}

      assert admin_user.id == author.user.id
      assert room.key == room_key
      assert receiver.id == following.from.id
      assert Ecto.assoc_loaded?(receiver.devices)
    end

    test "creates one-to-one chat", %{conn: conn, tokens: [author, _ | _]} do
      user = insert(:user)

      topic = "rooms:#{user.id}"
      Web.Endpoint.subscribe(topic)

      params = %{
        "one-to-one" => true,
        "add_users" => [user.id]
      }

      conn
      |> authenticate(author)
      |> post(Routes.chat_path(conn, :create), params)
      |> response(200)

      assert_received %Phoenix.Socket.Broadcast{
        event: "join",
        payload: %{room: %BillBored.Chat.Room{} = room},
        topic: ^topic
      }

      assert room.members |> Enum.map(& &1.id) |> Enum.sort() ==
               Enum.sort([user.id, author.user_id])
    end

    test "does not create one-to-one chat with same members", %{conn: conn} do
      [user1, user2] = insert_list(2, :user)

      chat_params = %{
        color: "",
        chat_type: "one-to-one",
        title: "One to One",
        private: true,
        last_interaction: DateTime.utc_now(),
        fake_location?: false
      }

      {:ok, room} = BillBored.Chat.Rooms.create(user2.id, chat_params, add_members: [user1.id])

      params = %{
        "one-to-one" => true,
        "add_users" => [user2.id]
      }

      assert %{
               "key" => key
             } =
               conn
               |> authenticate(insert(:auth_token, user: user1))
               |> post(Routes.chat_path(conn, :create), params)
               |> json_response(200)
      assert key == room.key
    end

    @tag :skip
    test "can be updated", %{conn: conn, tokens: [author | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "location" => [30.7008, 76.7885],
        "color" => "#FF006D",
        "reach_area_radius" => 20.0,
        "title" => "dropchat"
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.event_path(conn, :create, post.id), params)
        |> response(200)
        |> Jason.decode!()

      new_params = %{
        params
        | "buy_ticket_link" => "http://yandex.ru",
          "child_friendly" => false,
          "currency" => "RUB",
          "date" => "2019-08-16T01:51:09.427780Z",
          "price" => 1_000_000.4,
          "title" => "EVENT_UPD"
      }

      event = resp["result"]

      resp =
        conn
        |> authenticate(author.key)
        |> put(Routes.event_path(conn, :update, event["id"]), new_params)
        |> response(200)
        |> Jason.decode!()

      event = resp["result"]

      for field <- ["child_friendly", "buy_ticket_link", "currency", "date", "price", "title"] do
        assert event[field] == new_params[field]
      end
    end

    @tag :skip
    test "can be deleted", %{conn: conn, tokens: [author, other | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "buy_ticket_link" => "http://google.com",
        "child_friendly" => false,
        "currency" => "USD",
        "date" => "2019-07-16T01:51:09.427780Z",
        "location" => [
          30.7008,
          76.7885
        ],
        "media_file_keys" => [],
        "price" => 10,
        "title" => "EVENT"
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.event_path(conn, :create, post.id), params)
        |> response(200)
        |> Jason.decode!()

      event = resp["result"]

      _resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.event_path(conn, :show, event["id"]))
        |> response(200)
        |> Jason.decode!()

      # delete event
      conn
      |> authenticate(other.key)
      |> delete(Routes.event_path(conn, :delete, event["id"]))
      |> response(403)

      conn
      |> authenticate(author.key)
      |> delete(Routes.event_path(conn, :delete, event["id"]))
      |> response(204)

      conn
      |> authenticate(other.key)
      |> get(Routes.event_path(conn, :show, event["id"]))
      |> response(404)

      # no associations for post anymore

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.post_path(conn, :show, post.id))
        |> response(200)
        |> Jason.decode!()

      assert [] = resp["events"]
    end
  end

  describe "add_member" do
    setup do
      user = insert(:user)
      token = insert(:auth_token, user: user)

      %{user: user, token: token}
    end

    ["dropchat", "private-group-chat"]
    |> Enum.each(fn chat_type ->
      test "can add member to #{chat_type}", %{conn: conn, user: user, token: token} do
        chat_params = %{
          location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
          reach_area_radius: Decimal.new(20),
          color: "",
          chat_type: unquote(chat_type),
          title: unquote(chat_type),
          private: true,
          last_interaction: DateTime.utc_now(),
          fake_location?: false
        }

        {:ok, room} = BillBored.Chat.Rooms.create(user.id, chat_params)

        new_member = insert(:user)

        conn
        |> authenticate(token)
        |> put(Routes.chat_path(conn, :add_member, room.id, new_member.id))
        |> response(200)
      end
    end)

    test "can't add member to one-to-one chat", %{conn: conn, user: user, token: token} do
      chat_params = %{
        color: "",
        chat_type: "one-to-one",
        title: "One to one",
        private: true,
        last_interaction: DateTime.utc_now(),
        fake_location?: false
      }

      {:ok, room} =
        BillBored.Chat.Rooms.create(user.id, chat_params, add_members: [insert(:user).id])

      new_member = insert(:user)

      conn
      |> authenticate(token)
      |> put(Routes.chat_path(conn, :add_member, room.id, new_member.id))
      |> response(403)
    end

    test "add moderator to dropchat", %{conn: conn, user: user, token: token} do
      room = insert(:chat_room, chat_type: "dropchat")
      insert(:chat_room_administratorship, room: room, user: user)
      %{id: new_member_id} = insert(:user)

      conn
      |> authenticate(token)
      |> put(
        Routes.chat_path(conn, :add_member, room.id, new_member_id, %{"role" => "moderator"})
      )
      |> doc()
      |> response(200)

      assert [_, %{id: ^new_member_id, role: "moderator"}] =
               BillBored.Chat.Rooms.list_members(room.id)
               |> Enum.sort_by(fn %{role: role} -> role end)
    end

    test "change role from moderator to member", %{conn: conn, user: user, token: token} do
      room = insert(:chat_room, chat_type: "dropchat")
      insert(:chat_room_administratorship, room: room, user: user)
      %{id: moderator_id} = moderator = insert(:user)
      insert(:chat_room_membership, room: room, user: moderator, role: "moderator")

      conn
      |> authenticate(token)
      |> put(Routes.chat_path(conn, :add_member, room.id, moderator_id, %{"role" => "member"}))
      |> response(200)

      assert [_, %{id: ^moderator_id, role: "member"}] =
               BillBored.Chat.Rooms.list_members(room.id)
               |> Enum.sort_by(fn %{role: role} -> role end)
    end
  end

  describe "delete_member for dropchat" do
    setup do
      dropchat = insert(:chat_room, chat_type: "dropchat")
      admin = insert(:chat_room_administratorship, room: dropchat).user
      member = insert(:chat_room_membership, room: dropchat).user
      superuser = insert(:user, is_superuser: true)

      %{dropchat: dropchat, member: member, admin: admin, superuser: superuser}
    end

    test "admin can remove member", %{
      conn: conn,
      dropchat: dropchat,
      admin: admin,
      member: member
    } do
      token = insert(:auth_token, user: admin)

      conn
      |> authenticate(token.key)
      |> delete(Routes.chat_path(conn, :delete_member, dropchat.id, member.id))
      |> response(204)

      refute Memberships.get_by(user_id: member.id, room_key: dropchat.key)
      assert DropchatBans.exists?(dropchat, member)
    end

    test "superuser can remove member", %{
      conn: conn,
      dropchat: dropchat,
      superuser: superuser,
      member: member
    } do
      token = insert(:auth_token, user: superuser)

      conn
      |> authenticate(token.key)
      |> delete(Routes.chat_path(conn, :delete_member, dropchat.id, member.id))
      |> response(204)

      refute Memberships.get_by(user_id: member.id, room_key: dropchat.key)
      assert DropchatBans.exists?(dropchat, member)
    end

    test "another user can't remove member", %{conn: conn, dropchat: dropchat, member: member} do
      token = insert(:auth_token)

      conn
      |> authenticate(token.key)
      |> delete(Routes.chat_path(conn, :delete_member, dropchat.id, member.id))
      |> response(403)

      assert %Membership{} = Memberships.get_by(user_id: member.id, room_key: dropchat.key)
      refute DropchatBans.exists?(dropchat, member)
    end
  end

  describe "chat_search" do
    setup do
      user = insert(:user)
      token = insert(:auth_token, user: user)

      jack = insert(:user, username: "jack")
      sally = insert(:user, username: "sally")

      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "one-to-one",
        fake_location?: false
      }

      {:ok, oto_chat} = BillBored.Chat.Rooms.create(user.id, attrs, add_members: [jack.id])

      {:ok, dropchat} =
        BillBored.Chat.Rooms.create(user.id, Map.merge(attrs, %{chat_type: "dropchat"}),
          add_members: [sally.id]
        )

      %{
        user: user,
        token: token,
        rooms: [oto_chat, dropchat],
        oto_chat: oto_chat,
        dropchat: dropchat
      }
    end

    test "returns chats where current user is a member", %{conn: conn, token: token, rooms: rooms} do
      [key1, key2] = Enum.sort_by(rooms, & &1.key) |> Enum.map(& &1.key)

      assert [
               %{"key" => ^key1},
               %{"key" => ^key2}
             ] =
               conn
               |> authenticate(token.key)
               |> post(Routes.chat_path(conn, :chat_search))
               |> json_response(200)
               |> Enum.sort_by(& &1["key"])
    end

    test "returns chats where provided username is a member", %{
      conn: conn,
      token: token,
      dropchat: %{key: key}
    } do
      assert [
               %{"key" => ^key}
             ] =
               conn
               |> authenticate(token.key)
               |> post(Routes.chat_path(conn, :chat_search), %{"users" => ["sally"]})
               |> json_response(200)
    end

    test "returns chats of specified type", %{conn: conn, token: token, oto_chat: %{key: key}} do
      assert [
               %{"key" => ^key}
             ] =
               conn
               |> authenticate(token.key)
               |> post(Routes.chat_path(conn, :chat_search), %{"chat_types" => ["one-to-one"]})
               |> json_response(200)
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..10, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
