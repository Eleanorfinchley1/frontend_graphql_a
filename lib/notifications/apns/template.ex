defmodule Notifications.APNs.Template do
  @moduledoc false
  alias BillBored.{User, Post, Chat, Event, Livestream, Poll, PollItem, Notifications}

  # TODO move out Notifications.unread_count(user_id) calls out of this template module

  # TODO centralize "type"

  defp base_notification(message, device_token, unread_count, collapse_id \\ nil) do
    notification =
      message
      |> Pigeon.APNS.Notification.new(device_token, "com.BillBored.Thyne")
      |> Pigeon.APNS.Notification.put_sound("billborednoti.wav")
      |> Pigeon.APNS.Notification.put_badge(unread_count)

    %Pigeon.APNS.Notification{notification | collapse_id: collapse_id}
  end

  defp collapse_id(data) do
    Base.encode64(:crypto.hash(:md5, :erlang.term_to_binary(data)), padding: false)
  end

  def post_upvote_notifications(%Post.Upvote{
        user: %User{id: upvoter_id, username: liker_username},
        post: %Post{
          id: post_id,
          title: title,
          type: post_type,
          author: %User{id: author_id, devices: devices}
        }
      }) do
    message = "#{liker_username} liked your post #{title}"
    unread_count = Notifications.unread_count(author_id)

    payload = %{
      "type" => "posts:liked",
      "post" => %{
        "id" => post_id,
        "type" => post_type
      }
    }

    collapse_id = collapse_id(["posts:reaction", post_id, upvoter_id])

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count, collapse_id)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end

  def post_comment_notifications(%Post.Comment{
        author: %User{username: commenter_username},
        body: comment_body,
        post: %Post{
          id: post_id,
          type: post_type,
          author: %User{id: receiver_id, devices: receiver_devices}
        }
      }) do
    message = "#{commenter_username} commented on your post: #{comment_body}"
    unread_count = Notifications.unread_count(receiver_id)

    Enum.map(receiver_devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count)
      |> Pigeon.APNS.Notification.put_custom(%{
        "type" => "posts:commented",
        "post" => %{"id" => post_id, "type" => post_type}
      })
    end)
  end

  def post_comment_upvote_notifications(%Post.Comment.Upvote{
        user: %User{id: liker_id, username: liker_username},
        comment: %Post.Comment{
          id: comment_id,
          post_id: post_id,
          author: %User{id: author_id, devices: devices}
        }
      }) do
    message = "#{liker_username} liked your post comment"
    unread_count = Notifications.unread_count(author_id)

    payload = %{
      "type" => "post:comments:liked",
      "comment" => %{"id" => comment_id},
      "post" => %{"id" => post_id}
    }

    collapse_id = collapse_id(["post:comments:reaction", comment_id, liker_id])

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count, collapse_id)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end

  def post_approval_request_notifications(%Post.ApprovalRequest{
        approver: %User{id: approver_id, devices: devices},
        requester: %User{id: requester_id, username: requester_username},
        post_id: post_id
      }) do
    message = "#{requester_username} requested your approval for a post"
    unread_count = Notifications.unread_count(approver_id)

    payload = %{
      "type" => "post:approve:request",
      "request" => %{
        "post_id" => post_id,
        "requester" => %{
          "id" => requester_id,
          "username" => requester_username
        }
      }
    }

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end

  def post_approval_request_rejection_notifications(%Post.ApprovalRequest.Rejection{
        approver: %User{id: approver_id, username: approver_username},
        requester: %User{id: requester_id, devices: devices},
        post_id: post_id
      }) do
    message = "#{approver_username} rejected your post"
    unread_count = Notifications.unread_count(requester_id)

    payload = %{
      "type" => "post:approve:request:reject",
      "rejection" => %{
        "post_id" => post_id,
        "approver" => %{
          "id" => approver_id,
          "username" => approver_username
        }
      }
    }

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end

  def dropchat_privilege_request_notifications(
        request: %Chat.Room.ElevatedPrivilege.Request{
          id: request_id,
          user: %User{id: requester_id, username: requester_username}
        },
        receivers: receivers
      )
      when is_list(receivers) do
    message = "#{requester_username} requested write access"

    payload = %{
      "type" => "chats:privilege:request",
      "request" => %{
        "id" => request_id,
        "user" => %{
          "id" => requester_id,
          "username" => requester_username
        }
      }
    }

    receivers
    |> Notifications.zip_users_with_unread_counts()
    |> Enum.flat_map(fn {%User{devices: devices}, unread_count} ->
      Enum.map(devices, fn %User.Device{token: device_token} ->
        message
        |> base_notification(device_token, unread_count)
        |> Pigeon.APNS.Notification.put_custom(payload)
      end)
    end)
  end

  def dropchat_privilege_granted_notifications(%Chat.Room.ElevatedPrivilege{
        dropchat: %Chat.Room{id: room_id, title: room_title},
        user: %User{id: user_id, devices: devices}
      }) do
    message = "You've been granted access to post in #{room_title}!"
    unread_count = Notifications.unread_count(user_id)

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count)
      |> Pigeon.APNS.Notification.put_custom(%{
        "type" => "chats:privilege:granted",
        "room" => %{
          "id" => room_id,
          "title" => room_title
        }
      })
    end)
  end

  def chat_tagged_notifications(%{
        tagger: %User{username: tagger_username},
        message: %Chat.Message{message: message},
        room: %Chat.Room{key: chat_key, chat_type: chat_type, title: room_title},
        receivers: receivers
      })
      when is_list(receivers) do
    message = "#{tagger_username} tagged you in #{room_title}: #{message}"

    payload = %{
      "type" => "chats:message:tagged",
      "chat" => %{
        "type" => chat_type,
        "key" => chat_key
      }
    }

    receivers
    |> Notifications.zip_users_with_unread_counts()
    |> Enum.flat_map(fn {%User{devices: devices}, unread_count} ->
      Enum.map(devices, fn %User.Device{token: device_token} ->
        message
        |> base_notification(device_token, unread_count)
        |> Pigeon.APNS.Notification.put_custom(payload)
      end)
    end)
  end

  def chat_reply_notifications(
        sender: %User{username: sender_username},
        replied_to_message: %Chat.Message{user: %User{id: user_id, devices: devices}},
        reply: %Chat.Message{message: message},
        room: %Chat.Room{chat_type: chat_type, key: chat_key}
      ) do
    message = "#{sender_username} replied to you: #{message}"
    unread_count = Notifications.unread_count(user_id)

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count)
      |> Pigeon.APNS.Notification.put_custom(%{
        "type" => "chats:message:reply",
        "chat" => %{
          "type" => chat_type,
          "key" => chat_key
        }
      })
    end)
  end

  def chat_message_notifications(%{
        sender: %User{username: sender_username},
        message: %Chat.Message{message: message},
        room: %Chat.Room{key: chat_key, chat_type: chat_type},
        receivers: receivers
      })
      when is_list(receivers) do
    message = "#{sender_username}: #{message}"

    payload = %{
      "type" => "chats:message:new",
      "chat" => %{
        "type" => chat_type,
        "key" => chat_key
      }
    }

    receivers
    |> Notifications.zip_users_with_unread_counts()
    |> Enum.flat_map(fn {%User{devices: devices}, unread_count} ->
      Enum.map(devices, fn %User.Device{token: device_token} ->
        message
        |> base_notification(device_token, unread_count)
        |> Pigeon.APNS.Notification.put_custom(payload)
      end)
    end)
  end

  def matching_event_interests_notifications(
        event: %Event{id: event_id, title: event_title},
        receivers: receivers
      )
      when is_list(receivers) do
    message = "#{event_title} matches your interests"

    payload = %{
      "type" => "events:matching_interests",
      "event" => %{
        "id" => event_id,
        "title" => event_title
      }
    }

    receivers
    |> Notifications.zip_users_with_unread_counts()
    |> Enum.flat_map(fn {%User{devices: devices}, unread_count} ->
      Enum.map(devices, fn %User.Device{token: device_token} ->
        message
        |> base_notification(device_token, unread_count)
        |> Pigeon.APNS.Notification.put_custom(payload)
      end)
    end)
  end

  def published_livestream_notifications(
        livestream: %Livestream{
          id: livestream_id,
          title: livestream_title,
          owner: %User{id: owner_id, username: owner_username}
        },
        receivers: receivers
      )
      when is_list(receivers) do
    message = "#{owner_username} started a livestream #{livestream_title}"

    payload = %{
      "type" => "livestream:publish",
      "livestream" => %{
        "id" => livestream_id,
        "title" => livestream_title,
        "owner" => %{"id" => owner_id}
      }
    }

    receivers
    |> Notifications.zip_users_with_unread_counts()
    |> Enum.flat_map(fn {%User{devices: devices}, unread_count} ->
      Enum.map(devices, fn %User.Device{token: device_token} ->
        message
        |> base_notification(device_token, unread_count)
        |> Pigeon.APNS.Notification.put_custom(payload)
      end)
    end)
  end

  def new_following_notifications(%User.Followings.Following{
        id: following_id,
        to: %User{id: user_id, devices: devices},
        from: %User{username: follower_username, id: follower_id}
      }) do
    message = "#{follower_username} started following you"
    unread_count = Notifications.unread_count(user_id)

    payload = %{
      "type" => "following:new",
      "following" => %{
        "id" => following_id,
        "from" => %{"id" => follower_id, "username" => follower_username}
      }
    }

    collapse_id = collapse_id(["following:new", follower_id])

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count, collapse_id)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end

  def poll_vote_notifications(%PollItem.Vote{
        user: %User{id: voter_id, username: voter_username},
        poll_item: %PollItem{
          title: poll_item_title,
          poll: %Poll{
            id: poll_id,
            question: question,
            post: %Post{
              id: post_id,
              title: post_title,
              author: %User{id: user_id, devices: devices}
            }
          }
        }
      }) do
    message = "#{voter_username} voted on your poll #{post_title}"
    unread_count = Notifications.unread_count(user_id)

    payload = %{
      "type" => "poll_vote:new",
      "vote" => %{
        "item" => %{"title" => poll_item_title},
        "poll" => %{
          "id" => poll_id,
          "question" => question,
          "post" => %{
            "id" => post_id,
            "title" => post_title
          }
        }
      }
    }

    collapse_id = collapse_id(["poll_vote:new", poll_id, voter_id])

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count, collapse_id)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end

  def event_attending_notifications(%Event.Attendant{
        event: %Event{
          id: event_id,
          title: event_title,
          post: %Post{author: %User{id: user_id, devices: devices}}
        },
        user: %User{id: attendant_id, username: attendant_username}
      }) do
    message = "#{attendant_username} is going to attend your event #{event_title}"
    unread_count = Notifications.unread_count(user_id)

    payload = %{
      "type" => "event:attendant:new",
      "attendant" => %{"id" => attendant_id, "username" => attendant_username},
      "event" => %{"id" => event_id, "title" => event_title}
    }

    collapse_id = collapse_id(["event:attendant:new", event_id, attendant_id])

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count, collapse_id)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end

  def event_approaching_notifications(%Event.Attendant{
        event: %Event{id: event_id, title: event_title, date: event_date},
        user: %User{id: user_id, devices: devices}
      }) do
    hours_until_event = round(DateTime.diff(event_date, DateTime.utc_now()) / 3600)
    unread_count = Notifications.unread_count(user_id)

    message =
      if hours_until_event >= 2 do
        "#{event_title} is approaching. It starts in about #{hours_until_event} hours."
      else
        "#{event_title} is approaching"
      end

    collapse_id = collapse_id(["event:approaching", event_id])

    payload = %{
      "type" => "event:approaching",
      "event" => %{
        "id" => event_id,
        "title" => event_title,
        "event_date" => event_date
      }
    }

    Enum.map(devices, fn %User.Device{token: device_token} ->
      message
      |> base_notification(device_token, unread_count, collapse_id)
      |> Pigeon.APNS.Notification.put_custom(payload)
    end)
  end
end
