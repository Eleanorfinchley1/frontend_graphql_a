defmodule Web.ChatChannelTest do
  use Web.ChannelCase
  alias BillBored.{Chat, User, Post}

  setup do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
    %User{id: other_user_id} = insert(:user)
    %Chat.Room.Membership{room: %Chat.Room{} = room} = insert(:chat_room_membership, user: user)
    %Chat.Room.Administratorship{} = insert(:chat_room_administratorship, user: user, room: room)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

    %{user: user, other_user_id: other_user_id, room: room, socket: socket}
  end

  describe "join" do
    test "room which exists, user is a member", %{
      room: %Chat.Room{key: room_key, id: room_id},
      user: %User{id: user_id},
      socket: socket
    } do
      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "chats:#{room_key}", %{})

      assert socket.assigns.room.id == room_id
      assert socket.assigns.user.id == user_id
    end

    test "room which exists, user is not a member", %{socket: socket} do
      # creates a new room but without our user's membership
      %Chat.Room{id: room_id, key: room_key} = insert(:chat_room)

      assert {:error, %{"detail" => "user is not a member of the #{room_key} chat"}} ==
               subscribe_and_join(socket, "chats:#{room_id}", %{})
    end

    test "room which doesn't exist", %{socket: socket} do
      assert {:error, %{"detail" => "chat with key/id 0 does not exist"}} ==
               subscribe_and_join(socket, "chats:0", %{})
    end
  end

  describe "send message" do
    setup :subscribe_and_join

    test "which is valid", %{
      socket: socket,
      room: %Chat.Room{id: room_id},
      user: %User{id: user_id} = user
    } do
      message = %{"message" => "hello", "message_type" => "TXT"}
      ref = push(socket, "message:new", message)
      assert_reply(ref, :ok, %{"id" => new_message_id})

      # ensures message was saved
      assert %Chat.Message{
               user_id: ^user_id,
               message: "hello",
               message_type: "TXT",
               room_id: ^room_id
             } = saved_message = Chat.Messages.get_by(id: new_message_id)

      rendered_message =
        Web.MessageView.render("message.json", %{message: saved_message, user: user})

      assert_broadcast("message:new", ^rendered_message)
    end

    test "first message with usertags and second message right after", %{
      socket: socket,
      room: %Chat.Room{id: room_id},
      user: %User{id: user_id} = user,
      other_user_id: other_user_id
    } do
      message1 = %{
        "message" => "@testing07 #send",
        "hashtags" => ["send"],
        "usertags" => [%{"id" => other_user_id, "username" => "testing07"}],
        "message_type" => "TXT"
      }

      message2 = %{"message" => "hello", "message_type" => "TXT"}

      ref1 = push(socket, "message:new", message1)
      ref2 = push(socket, "message:new", message2)

      assert_reply(ref1, :ok, %{"id" => new_message_id1})
      assert_reply(ref2, :ok, %{"id" => new_message_id2})

      # ensures message was saved
      assert %Chat.Message{
               user_id: ^user_id,
               message: "@testing07 #send",
               message_type: "TXT",
               room_id: ^room_id
             } = saved_message1 = Chat.Messages.get_by(id: new_message_id1)

      assert %Chat.Message{
               user_id: ^user_id,
               message: "hello",
               message_type: "TXT",
               room_id: ^room_id
             } = saved_message2 = Chat.Messages.get_by(id: new_message_id2)

      rendered_message1 =
        Web.MessageView.render("message.json", %{message: saved_message1, user: user})

      rendered_message2 =
        Web.MessageView.render("message.json", %{message: saved_message2, user: user})

      assert_broadcast("message:new", ^rendered_message1)
      assert_broadcast("message:new", ^rendered_message2)
    end

    test "with private post", %{
      socket: socket,
      room: %Chat.Room{id: room_id},
      user: %User{id: user_id} = user
    } do
      %Post{id: private_post_id} =
        insert(:post, author: user, media_files: [build(:upload, owner: user)])

      message = %{
        "message" => "hello there post",
        "message_type" => "PST",
        "private_post_id" => private_post_id
      }

      ref = push(socket, "message:new", message)

      assert_reply(ref, :ok, %{"id" => new_message_id})

      # ensures message was saved with post
      assert %Chat.Message{
               user_id: ^user_id,
               message: "hello there post",
               message_type: "PST",
               room_id: ^room_id,
               private_post_id: ^private_post_id,
               private_post: %Post{}
             } =
               saved_message =
               Chat.Messages.get_by(id: new_message_id)
               |> Repo.preload(private_post: :media_files)

      rendered_message =
        Web.MessageView.render("message.json", %{message: saved_message, user: user})

      assert_broadcast("message:new", ^rendered_message)
    end

    test "which is invalid", %{socket: socket} do
      ref = push(socket, "message:new", %{})
      assert_reply(ref, :error, reply)
      assert reply == %{message_type: ["can't be blank"]}

      ref = push(socket, "message:new", %{"message_type" => "TXT"})
      assert_reply(ref, :error, reply)
      assert reply == %{message: ["can't be blank"]}
    end

    test "forward", %{socket: socket, user: user, room: room} do
      # creates another user whose message we forward
      other_user = insert(:user)

      # creates forwarded messages
      m1 = insert(:chat_message, user: other_user, room: room, message: "hey")

      ref = push(socket, "message:new", %{"forward" => %{"id" => m1.id}})
      assert_reply(ref, :ok, %{"id" => new_message_id, "created" => created})

      assert_broadcast("message:new", broadcasted)

      new_message = %{m1 | id: new_message_id, created: created}

      assert broadcasted ==
               Web.MessageView.render("message.json", %{message: new_message, user: user})
    end

    test "reply", %{socket: socket, room: room} do
      # creates another user to whom we reply
      other_user = insert(:user, username: "other_user_name")

      # creates replied to message
      %{id: m1_id} = m1 = insert(:chat_message, user: other_user, room: room, message: "hey")

      attrs = %{"message" => "hello", "message_type" => "TXT", "reply_to" => %{"id" => m1.id}}

      ref = push(socket, "message:new", attrs)

      assert_reply(ref, :ok, %{
        "id" => _new_message_id,
        "reply_to_username" => "other_user_name",
        "reply_to_avatar_thumbnail" => _avatar_thumbnail
      })

      assert_broadcast("message:new", %{"message" => %{"reply_to" => %{"id" => ^m1_id}}})
    end

    test "img", %{socket: socket, room: %Chat.Room{id: room_id}, user: %User{id: user_id} = user} do
      insert(:upload, owner: user, media_key: "a902c5b0-2a72-4e68-afa6-a1ed323cd721")

      message = %{
        "media_file_keys" => ["a902c5b0-2a72-4e68-afa6-a1ed323cd721"],
        "message_type" => "IMG"
      }

      ref = push(socket, "message:new", message)
      assert_reply(ref, :ok, %{"id" => new_message_id})

      # ensures message was saved
      assert %Chat.Message{
               user_id: ^user_id,
               message: "",
               message_type: "IMG",
               room_id: ^room_id,
               media_files: [%BillBored.Upload{media_key: "a902c5b0-2a72-4e68-afa6-a1ed323cd721"}]
             } =
               saved_message =
               Chat.Messages.get_by(id: new_message_id) |> Repo.preload(:media_files)

      rendered_message =
        Web.MessageView.render("message.json", %{message: saved_message, user: user})

      assert_broadcast("message:new", ^rendered_message)
    end
  end

  describe "send message to blocked users" do
    setup do
      %User.AuthToken{user: %User{} = blocked_user, key: token} = insert(:auth_token)
      block = insert(:user_block, blocked: blocked_user)

      %Chat.Room.Membership{room: %Chat.Room{key: room_key} = room} =
        insert(:chat_room_membership, user: blocked_user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "chats:#{room_key}", %{})

      %{socket: socket, blocked_user: blocked_user, room: room, blocker_user: block.blocker}
    end

    test "does not push to blocked user", %{
      socket: socket,
      blocker_user: blocker_user
    } do
      broadcast_from!(socket, "message:new", %{
        message: %{"message" => "blocked", "message_type" => "TXT"},
        user: blocker_user
      })

      broadcast_from!(socket, "message:new", %{
        message: %{"message" => "hello", "message_type" => "TXT"},
        user: insert(:user)
      })

      refute_push("message:new", %{message: %{"message" => "blocked"}})
      assert_push("message:new", %{message: %{"message" => "hello"}})
    end

    test "immediately blocks new pushes after user is blocked", %{
      socket: socket,
      blocked_user: blocked_user
    } do
      message = %{
        message: %{"message" => "hello", "message_type" => "TXT"},
        user: insert(:user)
      }

      broadcast_from!(socket, "message:new", message)
      assert_push("message:new", %{message: %{"message" => "hello"}})

      BillBored.User.Blocks.block(message[:user], blocked_user)

      broadcast_from!(socket, "message:new", message)
      refute_push("message:new", %{message: %{"message" => "hello"}})
    end

    test "immediately receives new pushes after user is unblocked", %{
      socket: socket,
      blocker_user: blocker_user,
      blocked_user: blocked_user
    } do
      message = %{
        message: %{"message" => "blocked", "message_type" => "TXT"},
        user: blocker_user
      }

      broadcast_from!(socket, "message:new", message)
      refute_push("message:new", %{message: %{"message" => "blocked"}})

      BillBored.User.Blocks.unblock(blocker_user, blocked_user)

      broadcast_from!(socket, "message:new", message)
      assert_push("message:new", %{message: %{"message" => "blocked"}})
    end
  end

  describe "send message from blocked user" do
    setup do
      %User.AuthToken{user: %User{} = blocker_user, key: token} = insert(:auth_token)
      block = insert(:user_block, blocker: blocker_user)

      %Chat.Room.Membership{room: %Chat.Room{key: room_key} = room} =
        insert(:chat_room_membership, user: blocker_user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "chats:#{room_key}", %{})

      %{socket: socket, blocker_user: blocker_user, room: room, blocked_user: block.blocked}
    end

    test "does not push from blocked user", %{
      socket: socket,
      blocked_user: blocked_user
    } do
      broadcast_from!(socket, "message:new", %{
        message: %{"message" => "blocked", "message_type" => "TXT"},
        user: blocked_user
      })

      broadcast_from!(socket, "message:new", %{
        message: %{"message" => "hello", "message_type" => "TXT"},
        user: insert(:user)
      })

      refute_push("message:new", %{message: %{"message" => "blocked"}})
      assert_push("message:new", %{message: %{"message" => "hello"}})
    end

    test "immediately blocks new pushes after user is blocked", %{
      socket: socket,
      blocker_user: blocker_user
    } do
      message = %{
        message: %{"message" => "hello", "message_type" => "TXT"},
        user: insert(:user)
      }

      broadcast_from!(socket, "message:new", message)
      assert_push("message:new", %{message: %{"message" => "hello"}})

      BillBored.User.Blocks.block(blocker_user, message[:user])

      broadcast_from!(socket, "message:new", message)
      refute_push("message:new", %{message: %{"message" => "hello"}})
    end

    test "immediately receives new pushes after user is unblocked", %{
      socket: socket,
      blocker_user: blocker_user,
      blocked_user: blocked_user
    } do
      message = %{
        message: %{"message" => "blocked", "message_type" => "TXT"},
        user: blocked_user
      }

      broadcast_from!(socket, "message:new", message)
      refute_push("message:new", %{message: %{"message" => "blocked"}})

      BillBored.User.Blocks.unblock(blocker_user, blocked_user)

      broadcast_from!(socket, "message:new", message)
      assert_push("message:new", %{message: %{"message" => "blocked"}})
    end
  end

  describe "typing" do
    setup :subscribe_and_join

    test "start", %{socket: socket, user: %User{id: user_id, username: username}} do
      ref = push(socket, "user:typing", %{"typing" => true})
      assert_reply(ref, :ok)

      join_key = to_string(user_id)

      assert_broadcast("presence_diff", %{
        joins: %{^join_key => %{metas: [%{typing: true, username: ^username}]}}
      })
    end

    # TODO maybe start and then stop
    test "stop", %{socket: socket, user: %User{id: user_id, username: username}} do
      ref = push(socket, "user:typing", %{"typing" => false})
      assert_reply(ref, :ok)

      join_key = to_string(user_id)

      assert_broadcast("presence_diff", %{
        joins: %{^join_key => %{metas: [%{typing: false, username: ^username}]}}
      })
    end
  end

  describe "fetch" do
    setup [:subscribe_and_join, :create_messages]

    test "after", %{socket: socket, messages: messages} do
      # fetches messages after second message
      ref = push(socket, "messages:fetch", %{"after" => %{"id" => Enum.at(messages, 1).id}})
      assert_reply(ref, :ok, reply)

      # skips first two messages
      new_messages =
        messages
        |> :lists.reverse()
        |> Enum.take(2)
        |> :lists.reverse()

      expected_messages = Web.MessageView.render("messages.json", %{messages: new_messages})

      assert reply == %{"messages" => expected_messages}
    end

    test "after for blocked user", %{socket: socket, messages: [m1, m2, m3, _m4]} do
      %{assigns: %{user: user}} = socket
      insert(:user_block, blocker: m1.user, blocked: user)

      # fetches messages after second message
      ref = push(socket, "messages:fetch", %{"after" => %{"id" => m2.id}})
      assert_reply(ref, :ok, reply)

      # m1 and m4 belong to blocker, m2 is base
      expected_messages = Web.MessageView.render("messages.json", %{messages: [m3]})

      assert reply == %{"messages" => expected_messages}
    end

    test "before", %{socket: socket, messages: messages} do
      # fetches messages before third message
      ref = push(socket, "messages:fetch", %{"before" => %{"id" => Enum.at(messages, 2).id}})
      assert_reply(ref, :ok, reply)

      # takes first two messages
      old_messages = Enum.take(messages, 2)

      expected_messages = Web.MessageView.render("messages.json", %{messages: old_messages})

      assert reply == %{"messages" => expected_messages}
    end

    test "before for blocked user", %{socket: socket, messages: [m1, m2, m3, _m4]} do
      %{assigns: %{user: user}} = socket
      insert(:user_block, blocker: m2.user, blocked: user)

      # fetches messages before third message
      ref = push(socket, "messages:fetch", %{"before" => %{"id" => m3.id}})
      assert_reply(ref, :ok, reply)

      expected_messages = Web.MessageView.render("messages.json", %{messages: [m1]})

      assert reply == %{"messages" => expected_messages}
    end
  end

  describe "user presence" do
    setup :subscribe_and_join

    test "notification on user join", %{user: %User{id: user_id, username: username}, room: room} do
      # creates another user who will join our room
      %User.AuthToken{
        user: %User{id: other_user_id, username: other_username} = other_user,
        key: token
      } = insert(:auth_token)

      insert(:chat_room_membership, user: other_user, room: room)

      spawn(fn ->
        {:ok, %Phoenix.Socket{} = other_socket} = connect(Web.UserSocket, %{"token" => token})

        {:ok, _reply, %Phoenix.Socket{}} =
          subscribe_and_join(other_socket, "chats:#{room.key}", %{})

        join_key = to_string(user_id)

        # asserts that we receive current room state for other user
        assert_push("presence_state", %{^join_key => %{metas: [%{username: ^username}]}})
      end)

      other_join_key = to_string(other_user_id)

      # asserts that we receive a notification about a new user
      assert_push("presence_diff", %{
        joins: %{^other_join_key => %{metas: [%{username: ^other_username}]}}
      })
    end

    test "notification on user leave", %{room: room} do
      # creates another user who will join our room
      %User.AuthToken{
        user: %User{id: other_user_id, username: other_username} = other_user,
        key: token
      } = insert(:auth_token)

      insert(:chat_room_membership, user: other_user, room: room)

      spawn(fn ->
        {:ok, %Phoenix.Socket{} = other_socket} = connect(Web.UserSocket, %{"token" => token})

        {:ok, _reply, other_socket} = subscribe_and_join(other_socket, "chats:#{room.key}", %{})

        # other user leaves the chat channel right after joining
        leave(other_socket)
      end)

      other_join_key = to_string(other_user_id)

      # asserts that we receive a notification about a leaving user
      assert_push("presence_diff", %{
        leaves: %{^other_join_key => %{metas: [%{username: ^other_username}]}}
      })
    end
  end

  defp subscribe_and_join(%{socket: %Phoenix.Socket{} = socket, room: %Chat.Room{key: room_key}}) do
    {:ok, _reply, %Phoenix.Socket{} = socket} =
      subscribe_and_join(socket, "chats:#{room_key}", %{})

    {:ok, %{socket: socket}}
  end

  defp create_messages(%{user: user, room: room}) do
    # creates another user we can chat with
    other_user = insert(:user)

    # creates four messages
    m1 = insert(:chat_message, user: user, room: room, message: "hey")
    m2 = insert(:chat_message, user: other_user, room: room, message: "hi")
    m3 = insert(:chat_message, user: other_user, room: room, message: "howdy")
    m4 = insert(:chat_message, user: user, room: room, message: "fine")

    # shouldn't be fetched, used is banned
    insert_list(2, :chat_message, room: room, user: insert(:user, banned?: true))

    {:ok, %{messages: [m1, m2, m3, m4]}}
  end
end
