defmodule Notifications.TemplateTest do
  use BillBored.DataCase, async: true

  alias Notifications.Template

  setup do
    receiver = insert(:user)

    receiver_devices = [
      insert(:user_device, user: receiver, platform: "android"),
      insert(:user_device, user: receiver, platform: "ios")
    ]

    %{
      receiver: %BillBored.User{receiver | devices: receiver_devices},
      receiver_devices: receiver_devices
    }
  end

  defp create_receivers(_ctx) do
    [r1, r2] = receivers = insert_list(2, :user)

    receivers_devices = [
      insert(:user_device, user: r1, platform: "ios"),
      insert(:user_device, user: r2, platform: "android")
    ]

    receivers = Repo.preload(receivers, [:devices]) |> Enum.sort_by(& &1.id)

    %{receivers: receivers, receivers_devices: receivers_devices}
  end

  defp sorted(notifications) do
    Enum.sort_by(notifications, fn
      %Pigeon.APNS.Notification{} -> 0
      %Pigeon.FCM.Notification{} -> 1
    end)
  end

  if filename = System.get_env("DUMP_NOTIFICATIONS") do
    defp doc([_apns, fcm] = notifications, name) do
      data = Jason.encode!(fcm.payload["data"], pretty: true)

      msg = """
      # #{name}

      ```json
      #{data}
      ```

      """

      {:ok, file} = File.open(unquote(filename), [:append])
      IO.write(file, msg)
      File.close(file)

      notifications
    end
  else
    defp doc(notifications, _name), do: notifications
  end

  describe "post_upvote_notifications/1" do
    setup(%{receiver: receiver}) do
      upvote =
        insert(:post_upvote,
          post: insert(:post, title: "Likable post", author: receiver),
          user: insert(:user, username: "liker001")
        )
        |> Repo.preload(user: [], post: [author: [:devices]])

      %{upvote: upvote}
    end

    test "returns correct notifications", %{
      upvote: %{post: %{id: post_id}} = upvote,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "liker001 liked your post Likable post",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "post" => %{
                     "id" => ^post_id,
                     "type" => "regular"
                   },
                   "type" => "posts:liked",
                   "notification_id" => 777
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "liker001 liked your post Likable post"},
                   "data" => %{
                     "post" => %{
                       "id" => ^post_id,
                       "type" => "regular"
                     },
                     "type" => "posts:liked",
                     "notification_id" => 777
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.post_upvote_notifications(upvote, payload: %{"notification_id" => 777})
               |> sorted()
               |> doc("Receiver's post was liked")
    end
  end

  describe "post_comment_notifications/1" do
    setup(%{receiver: receiver}) do
      comment =
        insert(:post_comment,
          body: "Awesome post!",
          post: insert(:post, title: "Controversial post", author: receiver),
          author: insert(:user, username: "commenter001")
        )
        |> Repo.preload(author: [], post: [author: [:devices]])

      %{comment: comment}
    end

    test "returns correct notifications", %{
      comment: %{post: %{id: post_id}} = comment,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "commenter001 commented on your post: Awesome post!",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "post" => %{
                     "id" => ^post_id,
                     "type" => "regular"
                   },
                   "type" => "posts:commented"
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "commenter001 commented on your post: Awesome post!"},
                   "data" => %{
                     "post" => %{
                       "id" => ^post_id,
                       "type" => "regular"
                     },
                     "type" => "posts:commented"
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.post_comment_notifications(comment)
               |> sorted()
               |> doc("Receiver's post got a new comment")
    end
  end

  describe "post_comment_upvote_notifications/1" do
    setup(%{receiver: receiver}) do
      comment_upvote =
        insert(:post_comment_upvote,
          comment: insert(:post_comment, body: "Likable comment", author: receiver),
          user: insert(:user, username: "liker002")
        )
        |> Repo.preload(user: [], comment: [post: [], author: [:devices]])

      %{comment_upvote: comment_upvote}
    end

    test "returns correct notifications", %{
      comment_upvote: %{comment: %{id: comment_id, post: %{id: post_id}}} = comment_upvote,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "liker002 liked your post comment",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "post:comments:liked",
                   "comment" => %{
                     "id" => ^comment_id
                   },
                   "post" => %{
                     "id" => ^post_id
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "liker002 liked your post comment"},
                   "data" => %{
                     "type" => "post:comments:liked",
                     "comment" => %{
                       "id" => ^comment_id
                     },
                     "post" => %{
                       "id" => ^post_id
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.post_comment_upvote_notifications(comment_upvote)
               |> sorted()
               |> doc("Receivers's post comment was liked")
    end
  end

  describe "post_approval_request_notifications/1" do
    setup(%{receiver: receiver}) do
      approval_request =
        insert(:post_approval_request,
          post: insert(:post),
          approver: receiver,
          requester: insert(:user, username: "requester001")
        )
        |> Repo.preload(approver: [:devices], requester: [])

      %{approval_request: approval_request}
    end

    test "returns correct notifications", %{
      approval_request:
        %{
          post_id: post_id,
          requester: %{
            id: requester_id,
            username: requester_username
          }
        } = approval_request,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "requester001 requested your approval for a post",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "post:approve:request",
                   "request" => %{
                     "post_id" => ^post_id,
                     "requester" => %{
                       "id" => ^requester_id,
                       "username" => ^requester_username
                     }
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "requester001 requested your approval for a post"},
                   "data" => %{
                     "type" => "post:approve:request",
                     "request" => %{
                       "post_id" => ^post_id,
                       "requester" => %{
                         "id" => ^requester_id,
                         "username" => ^requester_username
                       }
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.post_approval_request_notifications(approval_request)
               |> sorted()
               |> doc("Receivers's approval for a post was requested")
    end
  end

  describe "post_approval_request_rejection_notifications/1" do
    setup(%{receiver: receiver}) do
      approval_request_rejection =
        insert(:post_approval_request_rejection,
          post: insert(:post),
          approver: insert(:user, username: "rejecter001"),
          requester: receiver
        )
        |> Repo.preload(approver: [], requester: [:devices])

      %{approval_request_rejection: approval_request_rejection}
    end

    test "returns correct notifications", %{
      approval_request_rejection:
        %{
          post_id: post_id,
          approver: %{
            id: approver_id,
            username: approver_username
          }
        } = approval_request_rejection,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "rejecter001 rejected your post",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "post:approve:request:reject",
                   "rejection" => %{
                     "post_id" => ^post_id,
                     "approver" => %{
                       "id" => ^approver_id,
                       "username" => ^approver_username
                     }
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "rejecter001 rejected your post"},
                   "data" => %{
                     "type" => "post:approve:request:reject",
                     "rejection" => %{
                       "post_id" => ^post_id,
                       "approver" => %{
                         "id" => ^approver_id,
                         "username" => ^approver_username
                       }
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.post_approval_request_rejection_notifications(approval_request_rejection)
               |> sorted()
               |> doc("Receiver's post was rejected")
    end
  end

  describe "dropchat_privilege_request_notifications/1" do
    setup(ctx) do
      ctx = create_receivers(ctx)

      privilege_request =
        insert(:chat_room_elevated_privileges_request,
          user: insert(:user, username: "requester001")
        )
        |> Repo.preload(:user)

      Map.merge(ctx, %{privilege_request: privilege_request})
    end

    test "returns correct notifications", %{
      privilege_request:
        %{id: request_id, user: %{id: requester_id, username: requester_username}} =
          privilege_request,
      receivers: receivers,
      receivers_devices: [%{token: device_token1}, %{token: device_token2}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^device_token1,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "requester001 requested write access",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "chats:privilege:request",
                   "request" => %{
                     "id" => ^request_id,
                     "user" => %{
                       "id" => ^requester_id,
                       "username" => ^requester_username
                     }
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^device_token2,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "requester001 requested write access"},
                   "data" => %{
                     "type" => "chats:privilege:request",
                     "request" => %{
                       "id" => ^request_id,
                       "user" => %{
                         "id" => ^requester_id,
                         "username" => ^requester_username
                       }
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.dropchat_privilege_request_notifications(
                 request: privilege_request,
                 receivers: receivers
               )
               |> sorted()
               |> doc("Receivers' approval to grant chat access was requested")
    end
  end

  describe "dropchat_privilege_granted_notifications/1" do
    setup(%{receiver: receiver}) do
      elevated_privilege =
        insert(:chat_room_elevated_privilege,
          dropchat: insert(:chat_room, chat_type: "dropchat", title: "Dropchat 001"),
          user: receiver
        )
        |> Repo.preload(dropchat: [], user: [:devices])

      %{elevated_privilege: elevated_privilege}
    end

    test "returns correct notifications", %{
      elevated_privilege: %{dropchat: %{id: room_id, title: room_title}} = elevated_privilege,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "You've been granted access to post in Dropchat 001!",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "chats:privilege:granted",
                   "room" => %{
                     "id" => ^room_id,
                     "title" => ^room_title
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{
                     body: "You've been granted access to post in Dropchat 001!"
                   },
                   "data" => %{
                     "type" => "chats:privilege:granted",
                     "room" => %{
                       "id" => ^room_id,
                       "title" => ^room_title
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.dropchat_privilege_granted_notifications(elevated_privilege)
               |> sorted()
               |> doc("Receiver was granted access to post in a dropchat")
    end
  end

  describe "chat_tagged_notifications/1" do
    setup(ctx) do
      ctx = create_receivers(ctx)

      room = insert(:chat_room, title: "Room")

      message =
        insert(:chat_message,
          message: "Hello!",
          user: insert(:user, username: "tagger001"),
          room: room
        )
        |> Repo.preload(:user)

      Map.merge(ctx, %{
        room: room,
        message: message,
        tagger: message.user
      })
    end

    test "returns correct notifications", %{
      room: %{chat_type: chat_type, key: chat_key} = room,
      message: message,
      tagger: tagger,
      receivers: [r1, r2] = receivers,
      receivers_devices: [%{token: device_token1}, %{token: device_token2}]
    } do
      opts = [notification_ids: %{r1.id => 666, r2.id => 777}]

      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^device_token1,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "tagger001 tagged you in Room: Hello!",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "chats:message:tagged",
                   "chat" => %{
                     "type" => ^chat_type,
                     "key" => ^chat_key
                   },
                   "notification_id" => 666
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^device_token2,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "tagger001 tagged you in Room: Hello!"},
                   "data" => %{
                     "type" => "chats:message:tagged",
                     "chat" => %{
                       "type" => ^chat_type,
                       "key" => ^chat_key
                     },
                     "notification_id" => 777
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.chat_tagged_notifications(
                 %{
                   tagger: tagger,
                   message: message,
                   room: room,
                   receivers: receivers
                 },
                 opts
               )
               |> sorted()
               |> doc("Receivers' were tagged in a chat message")
    end
  end

  describe "chat_reply_notifications/1" do
    setup(%{receiver: receiver}) do
      room = insert(:chat_room)

      receiver_message =
        insert(:chat_message, room: room, user: receiver)
        |> Repo.preload(user: [:devices])

      reply_message =
        insert(:chat_message,
          room: room,
          message: "Yes",
          user: insert(:user, username: "sender001")
        )
        |> Repo.preload(:user)

      %{room: room, receiver_message: receiver_message, reply_message: reply_message}
    end

    test "returns correct notifications", %{
      room: %{chat_type: chat_type, key: chat_key} = room,
      receiver_message: receiver_message,
      reply_message: reply_message,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "sender001 replied to you: Yes",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "chats:message:reply",
                   "chat" => %{
                     "type" => ^chat_type,
                     "key" => ^chat_key
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "sender001 replied to you: Yes"},
                   "data" => %{
                     "type" => "chats:message:reply",
                     "chat" => %{
                       "type" => ^chat_type,
                       "key" => ^chat_key
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.chat_reply_notifications(
                 sender: reply_message.user,
                 replied_to_message: receiver_message,
                 reply: reply_message,
                 room: room,
                 muted?: false
               )
               |> sorted()
               |> doc("Receiver got a reply in chat")
    end
  end

  describe "chat_message_notifications/1" do
    setup(ctx) do
      ctx = create_receivers(ctx)

      room = insert(:chat_room)

      message =
        insert(:chat_message,
          message: "Hi!",
          room: room,
          user: insert(:user, username: "sender002")
        )
        |> Repo.preload(:user)

      Map.merge(ctx, %{
        room: room,
        message: message,
        sender: message.user
      })
    end

    test "returns correct notifications", %{
      room: %{chat_type: chat_type, key: chat_key} = room,
      message: message,
      sender: sender,
      receivers: receivers,
      receivers_devices: [%{token: device_token1}, %{token: device_token2}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^device_token1,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "sender002: Hi!",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "chats:message:new",
                   "chat" => %{
                     "type" => ^chat_type,
                     "key" => ^chat_key
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^device_token2,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "sender002: Hi!"},
                   "data" => %{
                     "type" => "chats:message:new",
                     "chat" => %{
                       "type" => ^chat_type,
                       "key" => ^chat_key
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.chat_message_notifications(%{
                 sender: sender,
                 message: message,
                 room: room,
                 receivers: receivers
               })
               |> sorted()
               |> doc("Receiver got a new chat message")
    end
  end

  describe "matching_event_interests_notifications/1" do
    setup(ctx) do
      ctx = create_receivers(ctx)

      event = insert(:event, title: "Event 001")

      Map.merge(ctx, %{event: event})
    end

    test "returns correct notifications", %{
      event: %{id: event_id, title: event_title} = event,
      receivers: receivers,
      receivers_devices: [%{token: device_token1}, %{token: device_token2}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^device_token1,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "Event 001 matches your interests",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "events:matching_interests",
                   "event" => %{
                     "id" => ^event_id,
                     "title" => ^event_title
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^device_token2,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "Event 001 matches your interests"},
                   "data" => %{
                     "type" => "events:matching_interests",
                     "event" => %{
                       "id" => ^event_id,
                       "title" => ^event_title
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.matching_event_interests_notifications(
                 event: event,
                 receivers: receivers
               )
               |> sorted()
               |> doc("Receivers have new event matching their interests")
    end
  end

  describe "published_livestream_notifications/1" do
    setup(ctx) do
      ctx = create_receivers(ctx)

      livestream =
        insert(:livestream, title: "Kittens", owner: insert(:user, username: "streamer001"))
        |> Repo.preload(:owner)

      Map.merge(ctx, %{livestream: livestream})
    end

    test "returns correct notifications", %{
      livestream:
        %{id: livestream_id, title: livestream_title, owner: %{id: owner_id}} = livestream,
      receivers: receivers,
      receivers_devices: [%{token: device_token1}, %{token: device_token2}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^device_token1,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "streamer001 started a livestream Kittens",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "livestream:publish",
                   "livestream" => %{
                     "id" => ^livestream_id,
                     "title" => ^livestream_title,
                     "owner" => %{"id" => ^owner_id}
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^device_token2,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "streamer001 started a livestream Kittens"},
                   "data" => %{
                     "type" => "livestream:publish",
                     "livestream" => %{
                       "id" => ^livestream_id,
                       "title" => ^livestream_title,
                       "owner" => %{"id" => ^owner_id}
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.published_livestream_notifications(
                 livestream: livestream,
                 receivers: receivers
               )
               |> sorted()
               |> doc("A new livestream was started")
    end
  end

  describe "new_following_notifications/1" do
    setup(%{receiver: receiver}) do
      following =
        insert(:user_following, from: insert(:user, username: "follower001"), to: receiver)
        |> Repo.preload(from: [], to: [:devices])

      %{following: following}
    end

    test "returns correct notifications", %{
      following:
        %{id: following_id, from: %{id: follower_id, username: follower_username}} = following,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "follower001 started following you",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "following:new",
                   "following" => %{
                     "id" => ^following_id,
                     "from" => %{
                       "id" => ^follower_id,
                       "username" => ^follower_username
                     }
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "follower001 started following you"},
                   "data" => %{
                     "type" => "following:new",
                     "following" => %{
                       "id" => ^following_id,
                       "from" => %{
                         "id" => ^follower_id,
                         "username" => ^follower_username
                       }
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.new_following_notifications(following)
               |> sorted()
               |> doc("Receiver got a new follower")
    end
  end

  describe "poll_vote_notifications/1" do
    setup(%{receiver: receiver}) do
      post = insert(:post, author: receiver, title: "Poll post")
      poll = insert(:poll, post: post)

      vote =
        insert(:poll_item_vote,
          user: insert(:user, username: "voter001"),
          poll_item: Enum.at(poll.items, 0)
        )
        |> Repo.preload(poll_item: [poll: [post: [author: [:devices]]]])

      %{post: post, poll: poll, vote: vote}
    end

    test "returns correct notifications", %{
      vote:
        %{
          poll_item: %{
            title: poll_item_title,
            poll: %{
              id: poll_id,
              question: question,
              post: %{
                id: post_id,
                title: post_title
              }
            }
          }
        } = vote,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "voter001 voted on your poll Poll post",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "poll_vote:new",
                   "vote" => %{
                     "item" => %{"title" => ^poll_item_title},
                     "poll" => %{
                       "id" => ^poll_id,
                       "question" => ^question,
                       "post" => %{
                         "id" => ^post_id,
                         "title" => ^post_title
                       }
                     }
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "voter001 voted on your poll Poll post"},
                   "data" => %{
                     "type" => "poll_vote:new",
                     "vote" => %{
                       "item" => %{"title" => ^poll_item_title},
                       "poll" => %{
                         "id" => ^poll_id,
                         "question" => ^question,
                         "post" => %{
                           "id" => ^post_id,
                           "title" => ^post_title
                         }
                       }
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.poll_vote_notifications(vote)
               |> sorted()
               |> doc("Receiver got a new vote in their poll post")
    end
  end

  describe "event_attending_notifications/1" do
    setup(%{receiver: receiver}) do
      post = insert(:post, type: "event", author: receiver)
      event = insert(:event, post: post, title: "Super event")

      attendant =
        insert(:event_attendant, event: event, user: insert(:user, username: "attendant001"))
        |> Repo.preload(user: [], event: [post: [author: [:devices]]])

      %{event: event, attendant: attendant}
    end

    test "returns correct notifications", %{
      attendant:
        %{
          event: %{
            id: event_id,
            title: event_title
          },
          user: %{
            id: attendant_id,
            username: attendant_username
          }
        } = attendant,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "attendant001 is going to attend your event Super event",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "event:attendant:new",
                   "attendant" => %{
                     "id" => ^attendant_id,
                     "username" => ^attendant_username
                   },
                   "event" => %{
                     "id" => ^event_id,
                     "title" => ^event_title
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{
                     body: "attendant001 is going to attend your event Super event"
                   },
                   "data" => %{
                     "type" => "event:attendant:new",
                     "attendant" => %{
                       "id" => ^attendant_id,
                       "username" => ^attendant_username
                     },
                     "event" => %{
                       "id" => ^event_id,
                       "title" => ^event_title
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.event_attending_notifications(attendant)
               |> sorted()
               |> doc("Receiver got a new attendant for their event")
    end
  end

  describe "event_approaching_notifications/1" do
    test "returns correct notifications for far event", %{
      receiver: receiver,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      event =
        %{id: event_id, title: event_title, date: event_date} =
        insert(:event, date: Timex.shift(Timex.now(), hours: 5), title: "Approaching event")

      attendant =
        insert(:event_attendant, event: event, user: receiver)
        |> Repo.preload(user: [:devices], event: [])

      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "Approaching event is approaching. It starts in about 5 hours.",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "event:approaching",
                   "event" => %{
                     "id" => ^event_id,
                     "title" => ^event_title,
                     "event_date" => ^event_date
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{
                     body: "Approaching event is approaching. It starts in about 5 hours."
                   },
                   "data" => %{
                     "type" => "event:approaching",
                     "event" => %{
                       "id" => ^event_id,
                       "title" => ^event_title,
                       "event_date" => ^event_date
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.event_approaching_notifications(attendant)
               |> sorted()
               |> doc("Receiver's event is approaching")
    end

    test "returns correct notifications for close event", %{
      receiver: receiver,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      event =
        %{id: event_id, title: event_title, date: event_date} =
        insert(:event, date: Timex.shift(Timex.now(), minutes: 30), title: "Approaching event")

      attendant =
        insert(:event_attendant, event: event, user: receiver)
        |> Repo.preload(user: [:devices], event: [])

      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "Approaching event is approaching",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "event:approaching",
                   "event" => %{
                     "id" => ^event_id,
                     "title" => ^event_title,
                     "event_date" => ^event_date
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{body: "Approaching event is approaching"},
                   "data" => %{
                     "type" => "event:approaching",
                     "event" => %{
                       "id" => ^event_id,
                       "title" => ^event_title,
                       "event_date" => ^event_date
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] = Template.event_approaching_notifications(attendant) |> sorted()
    end
  end

  describe "dropchat_stream_started_notifications" do
    setup [:create_receivers]

    test "returns correct notifications", %{
      receivers: receivers,
      receivers_devices: [%{token: ios_device_token}, %{token: android_device_token}]
    } do
      admin = insert(:user, username: "streamer001")
      %{key: room_key, id: room_id} = dropchat = insert(:chat_room, chat_type: "dropchat")
      stream = insert(:dropchat_stream, dropchat: dropchat, admin: admin, title: "Cats")

      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "streamer001 started a dropchat stream about \"Cats\"",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "dropchats:streams:new:followed",
                   "dropchat" => %{
                     "id" => ^room_id,
                     "key" => ^room_key,
                     "stream" => %{
                       "title" => "Cats"
                     }
                   }
                 },
                 push_type: "alert",
                 expiration: nil,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{
                     body: "streamer001 started a dropchat stream about \"Cats\""
                   },
                   "data" => %{
                     "type" => "dropchats:streams:new:followed",
                     "dropchat" => %{
                       "id" => ^room_id,
                       "key" => ^room_key,
                       "stream" => %{
                         "title" => "Cats"
                       }
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.dropchat_stream_started_notifications(%{
                 admin_user: admin,
                 room_key: room_key,
                 stream: stream,
                 receivers: receivers
               })
               |> sorted()
               |> doc("Receiver's followed user started a dropchat stream")
    end
  end

  describe "dropchat_stream_pinged" do
    test "returns correct notifications", %{
      receiver: receiver,
      receiver_devices: [%{token: android_device_token}, %{token: ios_device_token}]
    } do
      %{id: dropchat_id, key: dropchat_key} = dropchat = insert(:chat_room, chat_type: "dropchat")
      pinger = insert(:user, username: "pinger001")

      stream =
        insert(:dropchat_stream, admin: pinger, dropchat: dropchat, title: "Space")
        |> Repo.preload(:dropchat)

      assert [
               %Pigeon.APNS.Notification{
                 device_token: ^ios_device_token,
                 topic: "com.BillBored.Thyne",
                 collapse_id: _,
                 payload: %{
                   "aps" => %{
                     "alert" => "pinger001 recommends you a dropchat stream about \"Space\"",
                     "badge" => 0,
                     "sound" => "billborednoti.wav"
                   },
                   "type" => "dropchats:streams:recommendation",
                   "dropchat" => %{
                     "id" => ^dropchat_id,
                     "key" => ^dropchat_key,
                     "stream" => %{
                       "title" => "Space"
                     }
                   }
                 },
                 push_type: "alert",
                 expiration: 2145916800,
                 id: nil,
                 priority: nil,
                 response: nil
               },
               %Pigeon.FCM.Notification{
                 registration_id: ^android_device_token,
                 collapse_key: _,
                 time_to_live: _,
                 payload: %{
                   "notification" => %{
                     body: "pinger001 recommends you a dropchat stream about \"Space\""
                   },
                   "data" => %{
                     "dropchat" => %{
                       "id" => ^dropchat_id,
                       "key" => ^dropchat_key,
                       "stream" => %{
                         "title" => "Space"
                       }
                     }
                   }
                 },
                 priority: :normal,
                 response: [],
                 condition: nil,
                 content_available: false,
                 dry_run: false,
                 message_id: nil,
                 mutable_content: false,
                 restricted_package_name: nil,
                 status: nil
               }
             ] =
               Template.dropchat_stream_pinged(%{
                 stream: stream,
                 pinger_user: pinger,
                 pinged_user: receiver
               }, expires_at: ~U[2038-01-01 00:00:00Z])
               |> sorted()
               |> doc("Dropchat stream recommended")
    end
  end
end
