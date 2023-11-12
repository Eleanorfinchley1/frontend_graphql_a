defmodule Web.DropchatChannelTest do
  use Web.ChannelCase

  alias BillBored.{Chat, User, Upload}
  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStreams
  alias BillBored.UserPoints

  setup do
    %User.AuthToken{user: %User{} = user, key: token} =
      insert(:auth_token, user: insert(:user, username: "zod"))

    %Chat.Room{} =
      dropchat =
      insert(
        :chat_room,
        chat_type: "dropchat",
        location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
        private: false,
        reach_area_radius: 10
      )

    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

    dropchat = Repo.preload(dropchat, [:place])

    %{user: user, dropchat: dropchat, socket: socket}
  end

  describe "join" do
    test "within dropchat's reach", %{
      dropchat: %Chat.Room{id: dropchat_id, key: room_key} = dropchat,
      user: %User{id: user_id},
      socket: socket
    } do
      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert reply == %{
               "dropchat" =>
                 Web.RoomView.render("dropchat.json", %{
                   room: %{dropchat | members: [], administrators: [], moderators: []}
                 }),
               "priveleges" => [:read, :write, :listen]
             }

      assert socket.assigns.priveleges == [:read, :write, :listen]
      assert socket.assigns.user.id == user_id
      assert socket.assigns.room.id == dropchat.id
      refute socket.assigns.has_membership?

      # the write rights have been stored
      assert Repo.get_by(Chat.Room.ElevatedPrivilege, dropchat_id: dropchat_id, user_id: user_id)
    end

    test "with previous membership", %{
      dropchat: %Chat.Room{key: room_key} = dropchat,
      user: %User{id: user_id} = user,
      socket: socket
    } do
      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

      %Chat.Room.Membership{} = insert(:chat_room_membership, user: user, room: dropchat)

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert reply == %{
               "dropchat" =>
                 Web.RoomView.render("dropchat.json", %{
                   room: %{dropchat | members: [user], administrators: [], moderators: []}
                 }),
               "priveleges" => [:read, :write, :listen]
             }

      assert socket.assigns.priveleges == [:read, :write, :listen]
      assert socket.assigns.user.id == user_id
      assert socket.assigns.room.id == dropchat.id
      assert socket.assigns.has_membership?
    end

    # NOTE: Temporarily all users are granted elevated privileges!
    # TODO: Change this back
    test "outside of dropchat's reach without elevated privileges", %{
      dropchat: %Chat.Room{key: room_key} = dropchat,
      user: %User{id: user_id},
      socket: socket
    } do
      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert reply == %{
               "dropchat" =>
                 Web.RoomView.render("dropchat.json", %{
                   room: %{dropchat | members: [], administrators: [], moderators: []}
                 }),
               "priveleges" => [:read, :write, :listen]
             }

      assert socket.assigns.priveleges == [:read, :write, :listen]
      assert socket.assigns.user.id == user_id
      assert socket.assigns.room.id == dropchat.id
    end

    test "outside of dropchat's reach with elevated privileges", %{
      dropchat: %Chat.Room{key: room_key} = dropchat,
      user: %User{id: user_id} = user,
      socket: socket
    } do
      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      insert(:chat_room_elevated_privilege, user: user, dropchat: dropchat)

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert reply == %{
               "dropchat" =>
                 Web.RoomView.render("dropchat.json", %{
                   room: %{dropchat | members: [], administrators: [], moderators: []}
                 }),
               "priveleges" => [:read, :write, :listen]
             }

      assert socket.assigns.priveleges == [:read, :write, :listen]
      assert socket.assigns.user.id == user_id
      assert socket.assigns.room.id == dropchat.id
    end

    # NOTE: Temporarily all users are granted elevated privileges!
    # TODO: Change this back
    test "without location and privileges (from chat list screen)", %{
      dropchat: %Chat.Room{key: room_key} = dropchat,
      user: %User{id: user_id},
      socket: socket
    } do
      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{})

      assert reply == %{
               "dropchat" =>
                 Web.RoomView.render("dropchat.json", %{
                   room: %{dropchat | members: [], administrators: [], moderators: []}
                 }),
               "priveleges" => [:read, :write, :listen]
             }

      assert socket.assigns.priveleges == [:read, :write, :listen]
      assert socket.assigns.user.id == user_id
      assert socket.assigns.room.id == dropchat.id
    end

    test "with location and privileges (from chat list screen)", %{
      dropchat: %Chat.Room{key: room_key} = dropchat,
      user: %User{id: user_id} = user,
      socket: socket
    } do
      insert(:chat_room_elevated_privilege, user: user, dropchat: dropchat)

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{})

      assert reply == %{
               "dropchat" =>
                 Web.RoomView.render("dropchat.json", %{
                   room: %{dropchat | members: [], administrators: [], moderators: []}
                 }),
               "priveleges" => [:read, :write, :listen]
             }

      assert socket.assigns.priveleges == [:read, :write, :listen]
      assert socket.assigns.user.id == user_id
      assert socket.assigns.room.id == dropchat.id
    end

    test "room which doesn't exist", %{socket: socket} do
      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      assert {:error, %{"detail" => "chat for this key doesn't exist"}} ==
               subscribe_and_join(socket, "dropchats:asdf", %{"geometry" => user_location})
    end

    test "banned user joins with location", %{socket: socket, dropchat: dropchat, user: user} do
      insert(:dropchat_ban, dropchat: dropchat, banned_user: user)

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      assert {:error,
              %{"detail" => "Sorry, you can't join this dropchat because you have been banned."}} ==
               subscribe_and_join(socket, "dropchats:#{dropchat.key}", %{
                 "geometry" => user_location
               })
    end

    test "banned user joins without location", %{socket: socket, dropchat: dropchat, user: user} do
      insert(:dropchat_ban, dropchat: dropchat, banned_user: user)

      assert {:error,
              %{"detail" => "Sorry, you can't join this dropchat because you have been banned."}} ==
               subscribe_and_join(socket, "dropchats:#{dropchat.key}", %{})
    end

    test "renders active stream of dropchat", %{dropchat: dropchat, socket: socket, user: user} do
      stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          title: "Stream topic",
          reactions_count: %{"dislike" => 2},
          flags: %{"handraising_enabled" => true}
        )

      insert(:dropchat_stream_reaction, stream: stream, user: user, type: "like")

      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

      {:ok, reply, _} =
        subscribe_and_join(socket, "dropchats:#{dropchat.key}", %{"geometry" => user_location})

      assert %{
               "channel_name" => channel_name,
               "inserted_at" => _,
               "status" => "active",
               "title" => "Stream topic",
               "reactions_count" => %{
                 "like" => 0,
                 "dislike" => 2
               },
               "user_reactions" => %{
                 "dislike" => false,
                 "like" => true
               },
               "flags" => %{
                 "handraising_enabled" => true
               }
             } = reply["dropchat"]["active_stream"]

      assert channel_name == "#{dropchat.key}:#{stream.key}"
    end
  end

  describe "send message" do
    setup :subscribe_and_join

    # TODO refactor (find a simpler way to populate socket's priveleges)
    # NOTE: Temporarily all users are granted elevated privileges!
    # TODO: Change this back
    # test "when don't have write privileges" do
    #   %User.AuthToken{key: token} = insert(:auth_token)

    #   %Chat.Room{key: room_key} =
    #     insert(
    #       :chat_room,
    #       chat_type: "dropchat",
    #       location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
    #       private: false,
    #       reach_area_radius: 10
    #     )

    #   {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

    #   user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

    #   {:ok, _reply, %Phoenix.Socket{} = socket} =
    #     subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

    #   assert socket.assigns.priveleges == [:read, :listen]

    #   message = %{"message" => "hello", "message_type" => "TXT"}
    #   ref = push(socket, "message:new", message)

    #   assert_reply(ref, :error, %{"detail" => "user doesn't have write priveleges"})
    # end

    test "when don't have write privileges but has active stream with guest_chat_enabled", %{
      user: %User{id: user_id}
    } do
      %User.AuthToken{key: token} = insert(:auth_token)

      %Chat.Room{key: room_key} =
        dropchat =
        insert(
          :chat_room,
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          private: false,
          reach_area_radius: 10
        )

      insert(:dropchat_stream, dropchat: dropchat, flags: %{"guest_chat_enabled" => true})

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      # NOTE: Temporarily all users are granted elevated privileges!
      # TODO: Change this back
      assert socket.assigns.priveleges == [:read, :write, :listen]

      message = %{"message" => "hello", "message_type" => "TXT"}
      ref = push(socket, "message:new", message)

      assert_reply(ref, :ok, %{"id" => _new_message_id})

      refute Chat.Room.Memberships.get_by(user_id: user_id, room_id: dropchat.id)
    end

    test "membership is created after a message", %{
      socket: socket,
      dropchat: %Chat.Room{id: room_id},
      user: %User{id: user_id}
    } do
      message = %{"message" => "hello", "message_type" => "TXT"}
      ref = push(socket, "message:new", message)
      assert_reply(ref, :ok, %{"id" => _new_message_id})

      # TODO
      # assert socket.assigns.has_membership?
      assert Chat.Room.Memberships.get_by(user_id: user_id, room_id: room_id)
    end

    test "which is valid", %{
      socket: socket,
      dropchat: %Chat.Room{id: room_id},
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

    test "which is invalid", %{socket: socket} do
      ref = push(socket, "message:new", %{})
      assert_reply(ref, :error, reply)
      assert reply == %{message_type: ["can't be blank"]}

      ref = push(socket, "message:new", %{"message_type" => "TXT"})
      assert_reply(ref, :error, reply)
      assert reply == %{message: ["can't be blank"]}
    end

    test "forward", %{socket: socket, user: user, dropchat: room} do
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

    test "reply", %{socket: socket, dropchat: room} do
      # creates another user to whom we reply
      other_user = insert(:user)

      # creates replied to message
      %{id: m1_id} = m1 = insert(:chat_message, user: other_user, room: room, message: "hey")

      attrs = %{"message" => "hello", "message_type" => "TXT", "reply_to" => %{"id" => m1.id}}

      ref = push(socket, "message:new", attrs)
      assert_reply(ref, :ok, %{"id" => _new_message_id})
      assert_broadcast("message:new", %{"message" => %{"reply_to" => %{"id" => ^m1_id}}})
    end

    test "img", %{
      socket: socket,
      dropchat: %Chat.Room{id: room_id},
      user: %User{id: user_id} = user
    } do
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
               media_files: [%Upload{media_key: "a902c5b0-2a72-4e68-afa6-a1ed323cd721"}]
             } =
               saved_message =
               Chat.Messages.get_by(id: new_message_id) |> Repo.preload(:media_files)

      rendered_message =
        Web.MessageView.render("message.json", %{message: saved_message, user: user})

      assert_broadcast("message:new", ^rendered_message)
    end
  end

  describe "send message to blocked user" do
    setup do
      %User.AuthToken{user: %User{} = blocked_user, key: token} = insert(:auth_token)
      block = insert(:user_block, blocked: blocked_user)

      %Chat.Room{key: room_key} =
        dropchat =
        insert(
          :chat_room,
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          private: false,
          reach_area_radius: 10
        )

      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      %{
        socket: socket,
        blocked_user: blocked_user,
        dropchat: dropchat,
        blocker_user: block.blocker
      }
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

      %Chat.Room{key: room_key} =
        dropchat =
        insert(
          :chat_room,
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          private: false,
          reach_area_radius: 10
        )

      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      %{
        socket: socket,
        dropchat: dropchat,
        blocker_user: blocker_user,
        blocked_user: block.blocked
      }
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

  describe "members:list" do
    setup [:subscribe_and_join, :create_members]

    test "returns members list", %{
      socket: socket,
      dropchat: dropchat,
      user: %{id: user_id} = user,
      members: [
        %{user: %{id: m1_user_id}},
        %{user: %{id: m2_user_id}},
        %{user: %{id: m3_user_id}}
      ]
    } do
      insert(:chat_room_administratorship, room: dropchat, user: user)

      ref = push(socket, "members:list", %{})
      assert_reply(ref, :ok, reply)

      assert %{
               members: [
                 %{
                   id: ^m1_user_id,
                   role: "member",
                   privileges: ["read"]
                 },
                 %{
                   id: ^m2_user_id,
                   role: "member",
                   privileges: ["read", "write"]
                 },
                 %{
                   id: ^m3_user_id,
                   role: "moderator",
                   privileges: ["read"]
                 },
                 %{
                   id: ^user_id,
                   role: "administrator",
                   privileges: ["read", "write"]
                 }
               ]
             } = reply
    end
  end

  describe "dropchat ban event" do
    setup [:subscribe_and_join]

    test "channel terminates when user is banned from the dropchat", %{
      socket: %{channel_pid: channel_pid},
      dropchat: dropchat,
      user: user
    } do
      monitor_ref = Process.monitor(channel_pid)
      BillBored.Chat.Room.DropchatBans.create(dropchat, insert(:user), user)
      assert_receive {:DOWN, ^monitor_ref, _, _, :normal}
    end

    test "channel does not terminate when another user is banned from the dropchat", %{
      socket: %{channel_pid: channel_pid},
      dropchat: dropchat
    } do
      member = insert(:chat_room_membership, room: dropchat).user

      monitor_ref = Process.monitor(channel_pid)
      BillBored.Chat.Room.DropchatBans.create(dropchat, insert(:user), member)
      refute_receive {:DOWN, ^monitor_ref, _, _, :normal}
      Process.demonitor(monitor_ref, [:flush])
    end
  end

  describe "stream:start" do
    setup [:subscribe_and_join, :create_dropchat]

    setup do
      Phoenix.PubSub.subscribe(ExUnit.PubSub, "stubs:notifications")
      :ok
    end

    test "when user is admin", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      following = insert(:user_following, to: user)
      insert(:user_device, user: following.from)

      insert(:chat_room_administratorship, user: user, room: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:start", %{"title" => "New topic"})

      assert_reply(ref, :ok, %{
        "title" => "New topic",
        "status" => "active"
      })

      assert_push("stream:started", %{
        "title" => "New topic",
        "status" => "active"
      })

      assert %Chat.Room.DropchatStream{
               status: "active",
               title: "New topic"
             } = socket_state(socket).assigns[:room].active_stream

      assert_received {:process_dropchat_stream_started,
                       [%{receivers: receivers, stream: %{title: "New topic"}} = args]}

      assert Enum.at(receivers, 0).id == following.from.id
    end

    test "when user is not admin", %{dropchat: %Chat.Room{key: room_key}} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:start", %{"title" => "New topic"})
      assert_reply(ref, :error, %{"reason" => :user_not_admin})
      refute_push("stream:started", _)
    end

    test "when active stream already exists", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)
      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:start", %{"title" => "New topic"})
      assert_reply(ref, :error, %{"reason" => :active_stream_exists})
      refute_push("stream:started", _)
    end
  end

  describe "stream:finish" do
    setup [:subscribe_and_join, :create_dropchat]

    test "when user is admin", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)
      insert(:dropchat_stream, dropchat: dropchat, admin: user, title: "Stale topic")

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:finish", %{})

      assert_reply(ref, :ok, %{
        "title" => "Stale topic",
        "status" => "finished"
      })

      assert_push("stream:finished", %{
        "title" => "Stale topic",
        "status" => "finished"
      })

      refute socket_state(socket).assigns[:room].active_stream
    end

    test "when no active stream exists", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:finish", %{})
      assert_reply(ref, :error, %{"reason" => :no_active_stream})
      refute_push("stream:finished", _)
    end

    test "when user is not admin", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat, admin: user, title: "Stale topic")

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:finish", %{})
      assert_reply(ref, :error, %{"reason" => :insufficient_privileges})
      refute_push("stream:finished", _)
    end
  end

  describe "stream:get_token" do
    setup [:subscribe_and_join, :create_dropchat]

    test "returns publisher token for speaker", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:get_token", %{"role" => "publisher"})

      assert_reply(ref, :ok, %{
        "token" => "test-token",
        "role" => "publisher",
        "available_streaming_time" => 10800
      })
    end

    test "doesn't return token when no active stream exists", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user, status: "finished")
      insert(:dropchat_stream_speaker, stream: stream, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:get_token", %{"role" => "publisher"})
      assert_reply(ref, :error, %{"reason" => :no_active_stream})
    end

    test "returns subscriber token for privileged member", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_membership, user: user, room: dropchat)
      insert(:chat_room_elevated_privilege, dropchat: dropchat, user: user)
      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:get_token", %{"role" => "subscriber"})

      assert_reply(ref, :ok, %{
        "token" => "test-token",
        "role" => "subscriber",
        "available_streaming_time" => 10800
      })
    end

    test "returns token for guest user", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:get_token", %{"role" => "subscriber"})

      assert_reply(ref, :ok, %{
        "token" => "test-token",
        "role" => "subscriber",
        "available_streaming_time" => 10800
      })
    end

    test "doesn't return token when user has no available streaming time", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      now_ts = DateTime.to_unix(DateTime.utc_now())

      user =
        insert(:user,
          flags: %{
            "streaming_time_bucket" => now_ts - rem(now_ts, 86400),
            "streaming_time_remaining" => 0
          }
        )

      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:get_token", %{"role" => "publisher"})
      assert_reply(ref, :error, %{"reason" => :no_streaming_time_available})
    end
  end

  describe "stream:add_speaker" do
    setup [:subscribe_and_join, :create_dropchat]

    test "admin can add speaker to active stream", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:chat_room_administratorship, user: user, room: dropchat)
      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_speaker", %{"user_id" => speaker_id, "is_ghost" => false})
      assert_reply(ref, :ok, %{"speakers" => [%{id: ^speaker_id}]})

      assert_broadcast("stream:speaker_added", %{
        rendered_stream: rendered_stream,
        updated_dropchat: updated_dropchat
      })

      assert %{"speakers" => [%{id: ^speaker_id}]} = rendered_stream
      assert length(updated_dropchat.active_stream.speakers) == 1
    end

    test "moderator can add speaker to active stream", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:chat_room_membership, user: user, room: dropchat, role: "moderator")
      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_speaker", %{"user_id" => speaker_id, "is_ghost" => true})
      assert_reply(ref, :ok, %{"speakers" => [%{id: ^speaker_id}]})

      assert_broadcast("stream:speaker_added", %{
        rendered_stream: rendered_stream,
        updated_dropchat: updated_dropchat
      })

      assert %{"speakers" => [%{id: ^speaker_id}]} = rendered_stream
      assert length(updated_dropchat.active_stream.speakers) == 1
    end

    test "guest can't add speaker to active stream", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_speaker", %{"user_id" => speaker_id, "is_ghost" => false})
      assert_reply(ref, :error, %{"reason" => :insufficient_privileges})

      refute_broadcast("stream:speaker_added", _)
    end

    test "returns error when no active stream exists", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_speaker", %{"user_id" => 123, "is_ghost" => false})
      assert_reply(ref, :error, %{"reason" => :no_active_stream})

      refute_broadcast("stream:speaker_added", _)
    end

    test "returns error when missing param", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)
      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_speaker", %{})
      assert_reply(ref, :error, %{"reason" => :invalid_params})

      refute_broadcast("stream:speaker_added", _)
    end

    test "returns error when max speakers added", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:chat_room_administratorship, user: user, room: dropchat)
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert_list(6, :dropchat_stream_speaker, stream: stream)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_speaker", %{"user_id" => speaker_id, "is_ghost" => false})
      assert_reply(ref, :error, %{"reason" => :speakers_limit_reached})

      refute_broadcast("stream:speaker_added", _)
    end
  end

  describe "stream:remove_speaker" do
    setup [:subscribe_and_join, :create_dropchat]

    test "admin can remove speaker from active stream", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      speaker = %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:chat_room_administratorship, user: user, room: dropchat)
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: speaker)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert [%{id: ^speaker_id}] = reply["dropchat"]["active_stream"]["speakers"]

      ref = push(socket, "stream:remove_speaker", %{"user_id" => speaker_id})
      assert_reply(ref, :ok, %{"speakers" => []})

      assert_broadcast("stream:speaker_removed", %{
        rendered_stream: rendered_stream,
        updated_dropchat: updated_dropchat
      })

      assert %{"speakers" => []} = rendered_stream
      assert length(updated_dropchat.active_stream.speakers) == 0
    end

    test "moderator can remove speaker from active stream", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      speaker = %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:chat_room_membership, user: user, room: dropchat, role: "moderator")
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: speaker)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert [%{id: ^speaker_id}] = reply["dropchat"]["active_stream"]["speakers"]

      ref = push(socket, "stream:remove_speaker", %{"user_id" => speaker_id})
      assert_reply(ref, :ok, %{"speakers" => []})

      assert_broadcast("stream:speaker_removed", %{
        rendered_stream: rendered_stream,
        updated_dropchat: updated_dropchat
      })

      assert %{"speakers" => []} = rendered_stream
      assert length(updated_dropchat.active_stream.speakers) == 0
    end

    test "guest can't remove speaker from active stream", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      speaker = %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: speaker)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert [%{id: ^speaker_id}] = reply["dropchat"]["active_stream"]["speakers"]

      ref = push(socket, "stream:remove_speaker", %{"user_id" => speaker_id})
      assert_reply(ref, :error, %{"reason" => :insufficient_privileges})

      refute_broadcast("stream:speaker_removed", _)
    end

    test "returns error when no active stream exists", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:remove_speaker", %{"user_id" => 123})
      assert_reply(ref, :error, %{"reason" => :no_active_stream})

      refute_broadcast("stream:speaker_removed", _)
    end

    test "returns error when missing param", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)
      insert(:dropchat_stream, dropchat: dropchat, admin: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_speaker", %{})
      assert_reply(ref, :error, %{"reason" => :invalid_params})

      refute_broadcast("stream:speaker_removed", _)
    end

    test "does not broadcast stream:speaker_removed when no records were deleted", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      speaker = %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:chat_room_administratorship, user: user, room: dropchat)
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: speaker)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert [%{id: ^speaker_id}] = reply["dropchat"]["active_stream"]["speakers"]

      ref = push(socket, "stream:remove_speaker", %{"user_id" => 123})
      assert_reply(ref, :ok, %{"speakers" => [%{id: ^speaker_id}]})

      refute_broadcast("stream:speaker_removed", _)
    end

    test "moderator can't remove admin speaker", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      speaker = %{id: speaker_id} = insert(:user)
      UserPoints.give_signup_points(speaker_id)
      insert(:chat_room_membership, user: user, room: dropchat, role: "moderator")
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: speaker)
      insert(:dropchat_stream_speaker, stream: stream, user: speaker)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      assert [%{id: ^speaker_id}] = reply["dropchat"]["active_stream"]["speakers"]

      ref = push(socket, "stream:remove_speaker", %{"user_id" => speaker_id})
      assert_reply(ref, :error, %{"reason" => :insufficient_privileges})

      refute_broadcast("stream:speaker_removed", _)
    end
  end

  describe "stream:streaming:tick" do
    setup [:subscribe_and_join, :create_dropchat]

    test "speaker receives updates of available streaming time", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      BillBored.Users.subtract_available_streaming_time(user, 0)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      start_ts = DateTime.to_unix(DateTime.utc_now()) - 5_000
      send(socket.channel_pid, {:update_streaming_time, start_ts})

      # 5800
      assert_push("stream:streaming:tick", %{"available_streaming_time" => time})
      assert abs(5800 - time) <= 5

      assert abs(5800 - socket_state(socket).assigns[:user].flags["streaming_time_remaining"]) <=
               5
    end
  end

  describe "stream:streaming:start" do
    setup [:subscribe_and_join, :create_dropchat]

    test "starts counting down streaming time", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:streaming:start", %{})
      assert_reply(ref, :ok, %{"available_streaming_time" => 10800})
    end
  end

  describe "stream:streaming:stop" do
    setup [:subscribe_and_join, :create_dropchat]

    test "stops counting down streaming time", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_administratorship, user: user, room: dropchat)
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: user)
      insert(:dropchat_stream_speaker, stream: stream, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:streaming:stop", %{})
      assert_reply(ref, :ok, %{"available_streaming_time" => 10800})
    end
  end

  describe "stream:add_reaction" do
    setup [:subscribe_and_join, :create_dropchat]

    test "user can add like", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_reaction", %{"type" => "like"})

      assert_reply(ref, :ok, %{
        "reactions_count" => %{"like" => 1},
        "user_reactions" => %{
          "like" => true,
          "dislike" => false
        }
      })

      assert_broadcast("stream:updated", %{
        event_type: "reaction_added",
        rendered_stream: rendered_stream,
        updated_dropchat: updated_dropchat
      })

      assert %{"reactions_count" => %{"like" => 1}} = rendered_stream
    end

    test "returns error on missing params", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_reaction", %{})
      assert_reply(ref, :error, %{"reason" => :invalid_params})

      refute_broadcast("stream:updated", _)
    end

    test "returns error on invalid reaction type", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:add_reaction", %{"type" => "yay"})
      assert_reply(ref, :error, %{"reason" => :invalid_params})

      refute_broadcast("stream:updated", _)
    end
  end

  describe "stream:remove_reaction" do
    setup [:subscribe_and_join, :create_dropchat]

    test "user can remove like", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      stream = insert(:dropchat_stream, dropchat: dropchat, reactions_count: %{"like" => 10})
      insert(:dropchat_stream_reaction, stream: stream, user: user, type: "like")

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:remove_reaction", %{"type" => "like"})

      assert_reply(ref, :ok, %{
        "reactions_count" => %{"like" => 9},
        "user_reactions" => %{
          "like" => false,
          "dislike" => false
        }
      })

      assert_broadcast("stream:updated", %{
        event_type: "reaction_removed",
        rendered_stream: rendered_stream,
        updated_dropchat: updated_dropchat
      })

      assert %{"reactions_count" => %{"like" => 9}} = rendered_stream
    end

    test "returns error on missing params", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:remove_reaction", %{})
      assert_reply(ref, :error, %{"reason" => :invalid_params})

      refute_broadcast("stream:updated", _)
    end

    test "returns error on invalid reaction type", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:remove_reaction", %{"type" => "nay"})
      assert_reply(ref, :error, %{"reason" => :invalid_params})

      refute_broadcast("stream:updated", _)
    end
  end

  describe "stream:audience:join" do
    setup [:subscribe_and_join, :create_dropchat]

    test "adds user as stream audience member", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:audience:join", %{})
      assert_reply(ref, :ok, %{"live_audience_count" => 1})

      assert_broadcast("stream:updated", %{
        event_type: "audience_joined",
        rendered_stream: rendered_stream
      })

      assert %{"live_audience_count" => 1} = rendered_stream
    end
  end

  describe "stream:audience:leave" do
    setup [:subscribe_and_join, :create_dropchat]

    test "removes user from stream audience members", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)

      stream = insert(:dropchat_stream, dropchat: dropchat)
      Chat.Room.DropchatStreams.add_live_audience_member(stream, user.id)

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        socket(Web.UserSocket, "user:#{user.id}", %{user: user, audience_stream: stream})
        |> subscribe_and_join("dropchats:#{room_key}", %{"geometry" => user_location})

      assert 1 == Chat.Room.DropchatStreams.live_audience_count(stream)

      ref = push(socket, "stream:audience:leave", %{})
      assert_reply(ref, :ok, _)

      assert_broadcast("stream:updated", %{
        event_type: "audience_left",
        rendered_stream: rendered_stream
      })

      assert %{"live_audience_count" => 0} = rendered_stream

      assert 0 == Chat.Room.DropchatStreams.live_audience_count(stream)
    end

    test "returns error if user haven't joined audience", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)

      stream = insert(:dropchat_stream, dropchat: dropchat)
      Chat.Room.DropchatStreams.add_live_audience_member(stream, user.id)

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        socket(Web.UserSocket, "user:#{user.id}", %{user: user})
        |> subscribe_and_join("dropchats:#{room_key}", %{"geometry" => user_location})

      assert 1 == Chat.Room.DropchatStreams.live_audience_count(stream)

      ref = push(socket, "stream:audience:leave", %{})
      assert_reply(ref, :error, %{"reason" => :not_audience_member})

      refute_broadcast("stream:updated", _)

      assert 1 == Chat.Room.DropchatStreams.live_audience_count(stream)
    end
  end

  describe "stream:flags:update" do
    setup [:subscribe_and_join, :create_dropchat]

    test "updates active stream flags", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref =
        push(socket, "stream:flags:update", %{"flag" => "handraising_enabled", "value" => true})

      assert_reply(ref, :ok, %{"flags" => %{"handraising_enabled" => true}})

      assert_broadcast("stream:updated", %{
        event_type: "flags_updated",
        rendered_stream: %{"flags" => %{"handraising_enabled" => true}}
      })

      ref2 =
        push(socket, "stream:flags:update", %{"flag" => "guest_chat_enabled", "value" => true})

      assert_reply(ref2, :ok, %{"flags" => %{"guest_chat_enabled" => true}})

      assert_broadcast("stream:updated", %{
        event_type: "flags_updated",
        rendered_stream: %{
          "flags" => %{"handraising_enabled" => true, "guest_chat_enabled" => true}
        }
      })
    end

    test "returns error when no active stream exists", %{dropchat: %Chat.Room{key: room_key}} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref =
        push(socket, "stream:flags:update", %{"flag" => "handraising_enabled", "value" => true})

      assert_reply(ref, :error, %{"reason" => :no_active_stream})

      refute_broadcast("stream:updated", _)
    end

    test "returns error when missing params", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:flags:update", %{"flag" => "handraising_enabled"})

      assert_reply(ref, :error, %{
        "reason" => :invalid_params,
        "detail" => "missing required params: value"
      })

      refute_broadcast("stream:updated", _)
    end

    test "returns error when invalid param type", %{
      dropchat: %Chat.Room{key: room_key} = dropchat
    } do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref =
        push(socket, "stream:flags:update", %{"flag" => "handraising_enabled", "value" => "oops"})

      assert_reply(ref, :error, %{"reason" => :invalid_param_type})

      refute_broadcast("stream:updated", _)
    end

    test "returns error when invalid flag name", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref =
        push(socket, "stream:flags:update", %{"flag" => "handraising_disable", "value" => false})

      assert_reply(ref, :error, %{"reason" => :invalid_flag})

      refute_broadcast("stream:updated", _)
    end
  end

  describe "stream:audience:raise_hand" do
    setup [:subscribe_and_join, :create_dropchat]

    test "sets hand_raised user presence", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:chat_room_membership, user: user, room: dropchat)
      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:audience:raise_hand", %{"is_ghost" => false})
      assert_reply(ref, :ok)

      refute_broadcast("stream:updated", _)

      user_id_ref = to_string(user.id)

      assert_push("presence_diff", %{
        joins: %{^user_id_ref => %{metas: [%{hand_raised: true}]}}
      })
    end

    test "returns error when no active stream", %{dropchat: %Chat.Room{key: room_key}} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:audience:raise_hand", %{"is_ghost" => false})
      assert_reply(ref, :error, %{"reason" => :no_active_stream})

      refute_broadcast("stream:updated", _)

      user_id_ref = to_string(user.id)

      refute_push("presence_diff", %{
        joins: %{^user_id_ref => %{metas: [%{hand_raised: true}]}}
      })
    end
  end

  describe "stream:audience:lower_hand" do
    setup [:subscribe_and_join, :create_dropchat]

    test "sets hand_raised user presence", %{dropchat: %Chat.Room{key: room_key}} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:audience:lower_hand", %{})
      assert_reply(ref, :ok)

      refute_broadcast("stream:updated", _)

      user_id_ref = to_string(user.id)

      assert_push("presence_diff", %{
        joins: %{^user_id_ref => %{metas: [%{hand_raised: false}]}}
      })
    end
  end

  describe "stream:recommend" do
    setup [:subscribe_and_join, :create_dropchat]

    setup do
      Phoenix.PubSub.subscribe(ExUnit.PubSub, "stubs:notifications")
      :ok
    end

    test "sends recommendation push notification", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)
      pinged_user = %{id: pinged_user_id} = insert(:user)

      insert(:user_following, from: pinged_user, to: user)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:recommend", %{"user_id" => pinged_user_id})
      assert_reply(ref, :ok)

      assert_received {:process_dropchat_stream_pinged, [%{stream: stream, pinged_user: %{id: ^pinged_user_id}}]}
      assert Ecto.assoc_loaded?(stream.dropchat)
    end

    test "returns error if user already pinged", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      stream = insert(:dropchat_stream, dropchat: dropchat)
      pinged_user = %{id: pinged_user_id} = insert(:user)

      insert(:user_following, from: pinged_user, to: user)

      redis_key = DropchatStreams.dropchat_stream_ping_key(stream.id, user.id, pinged_user_id)
      {:ok, "OK"} = BillBored.Stubs.Redix.command(["SET", redis_key, "1"])

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:recommend", %{"user_id" => pinged_user_id})
      assert_reply(ref, :error, %{"reason" => :already_sent})

      refute_received {:process_dropchat_stream_pinged, [%{pinged_user: %{id: ^pinged_user_id}}]}
    end

    test "returns error when missing required param", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "stream:recommend", %{})
      assert_reply(ref, :error, %{"reason" => :invalid_params})
    end
  end

  describe "notify_stream_event" do
    setup [:subscribe_and_join, :create_dropchat]

    test "sends updated stream event", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      stream = insert(:dropchat_stream, dropchat: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      updated_stream =
        stream
        |> Ecto.Changeset.change(%{recording_data: %{status: "started"}})
        |> Repo.update!()

      Web.DropchatChannel.notify_stream_event(updated_stream, "stream:recording:finished")

      assert_broadcast("stream:recording:finished", %{rendered_stream: rendered_stream})
      assert %{"recording" => %{status: "started"}} = rendered_stream
    end
  end

  describe "streams:list" do
    setup [:subscribe_and_join, :create_dropchat]

    test "returns all dropchat streams", %{dropchat: %Chat.Room{key: room_key} = dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      %User.AuthToken{key: token} = insert(:auth_token, user: user)

      _s1 =
        insert(:dropchat_stream,
          dropchat: dropchat,
          status: "finished",
          recording_data: %DropchatStream.RecordingData{
            status: "expired",
            files: [%{"fileName" => "sid_channel-123.m3u8"}]
          },
          inserted_at: Timex.shift(Timex.now(), days: -15)
        )

      _s2 =
        insert(:dropchat_stream,
          dropchat: dropchat,
          status: "finished",
          recording_data: %DropchatStream.RecordingData{
            status: "finished",
            files: [%{"fileName" => "sid_channel-234.m3u8"}]
          },
          inserted_at: Timex.shift(Timex.now(), days: -3)
        )

      _s3 =
        insert(:dropchat_stream,
          dropchat: dropchat,
          status: "finished",
          recording_data: %DropchatStream.RecordingData{
            status: "failed",
            files: [%{"fileName" => "sid_channel-345.m3u8"}]
          },
          inserted_at: Timex.shift(Timex.now(), minutes: -5)
        )

      s4 = insert(:dropchat_stream, dropchat: dropchat, status: "active")
      insert(:dropchat_stream_speaker, stream: s4)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

      ref = push(socket, "streams:list", %{})
      assert_reply(ref, :ok, %{"streams" => streams})

      assert [
               %{
                 "recording" => nil,
                 "speakers" => [%{id: _}],
                 "status" => "active"
               },
               %{
                 "recording" => %{
                   status: "failed",
                   urls: []
                 },
                 "speakers" => [],
                 "status" => "finished"
               },
               %{
                 "recording" => %{
                   status: "finished",
                   urls: ["https://test-bucket.aws/sid_channel-234.m3u8"]
                 },
                 "speakers" => [],
                 "status" => "finished"
               },
               %{
                 "recording" => %{
                   status: "expired",
                   urls: []
                 },
                 "speakers" => [],
                 "status" => "finished"
               }
             ] = streams
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

    test "notification on user join", %{
      user: %User{id: user_id, username: username},
      dropchat: dropchat
    } do
      # creates another user who will join our dropchat channel
      %User.AuthToken{
        user: %User{id: other_user_id, username: other_username},
        key: token
      } = insert(:auth_token)

      spawn(fn ->
        {:ok, %Phoenix.Socket{} = other_socket} = connect(Web.UserSocket, %{"token" => token})

        user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

        {:ok, _reply, %Phoenix.Socket{}} =
          subscribe_and_join(other_socket, "dropchats:#{dropchat.key}", %{
            "geometry" => user_location
          })

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

    test "notification on user leave", %{dropchat: dropchat} do
      # creates another user who will join our dropchat channel
      %User.AuthToken{
        user: %User{id: other_user_id, username: other_username},
        key: token
      } = insert(:auth_token)

      spawn(fn ->
        {:ok, %Phoenix.Socket{} = other_socket} = connect(Web.UserSocket, %{"token" => token})

        user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

        {:ok, _reply, other_socket} =
          subscribe_and_join(other_socket, "dropchats:#{dropchat.key}", %{
            "geometry" => user_location
          })

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

  describe "privileges" do
    import Plug.Conn
    import Phoenix.ConnTest, except: [connect: 2]
    alias Web.Router.Helpers, as: Routes

    # TODO simplify
    test "privilege:granted" do
      # creates our requester
      %User.AuthToken{user: %User{} = requester, key: token} = insert(:auth_token)
      %User.AuthToken{user: %User{} = admin, key: admin_token} = insert(:auth_token)

      %Chat.Room{} =
        dropchat =
        insert(
          :chat_room,
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          private: false,
          reach_area_radius: 10
        )

      insert(:chat_room_administratorship, user: admin, room: dropchat)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      user_location = %{"type" => "Point", "coordinates" => [30.5, -50.0]}

      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "dropchats:#{dropchat.key}", %{"geometry" => user_location})

      request = insert(:chat_room_elevated_privileges_request, user: requester, room: dropchat)

      conn = Phoenix.ConnTest.build_conn()

      # grants an elevated privilege for our user
      assert %{"granted_privilege" => %{"id" => _id}} =
               conn
               |> put_req_header("authorization", "Bearer #{admin_token}")
               |> post(Routes.dropchat_path(conn, :grant_request), %{"request_id" => request.id})
               |> json_response(200)

      assert_push("privilege:granted", payload)

      assert payload == %{}
    end
  end

  defp subscribe_and_join(%{
         socket: %Phoenix.Socket{} = socket,
         dropchat: %Chat.Room{key: room_key}
       }) do
    user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

    {:ok, _reply, %Phoenix.Socket{} = socket} =
      subscribe_and_join(socket, "dropchats:#{room_key}", %{"geometry" => user_location})

    {:ok, %{socket: socket}}
  end

  defp create_dropchat(_) do
    %{
      dropchat:
        insert(
          :chat_room,
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          private: false,
          reach_area_radius: 10
        )
    }
  end

  defp create_members(%{dropchat: dropchat}) do
    m1 = insert(:chat_room_membership, room: dropchat, user: insert(:user, username: "aaron1"))
    m2 = insert(:chat_room_membership, room: dropchat, user: insert(:user, username: "aaron2"))

    m3 =
      insert(:chat_room_membership,
        room: dropchat,
        role: "moderator",
        user: insert(:user, username: "mod_joe")
      )

    insert(:chat_room_elevated_privilege, dropchat: dropchat, user: m2.user)

    {:ok, %{members: [m1, m2, m3]}}
  end

  defp create_messages(%{user: user, dropchat: dropchat}) do
    # creates another user we can chat with
    other_user = insert(:user)

    # creates four messages
    m1 = insert(:chat_message, user: user, room: dropchat, message: "hey")
    m2 = insert(:chat_message, user: other_user, room: dropchat, message: "hi")
    m3 = insert(:chat_message, user: other_user, room: dropchat, message: "howdy")
    m4 = insert(:chat_message, user: user, room: dropchat, message: "fine")

    # shouldn't be fetched, used is banned
    insert_list(2, :chat_message, room: dropchat, user: insert(:user, banned?: true))

    {:ok, %{messages: [m1, m2, m3, m4]}}
  end
end
