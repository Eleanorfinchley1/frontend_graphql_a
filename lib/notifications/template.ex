defmodule Notifications.Template do
  @moduledoc false
  alias BillBored.{User, Post, Chat, Event, Livestream, Poll, PollItem, Notification, Notifications}

  defp default_apns_options() do
    Application.fetch_env!(:billbored, __MODULE__)[:default_apns_options]
  end

  defp build_notifications(devices, message, payload, opts) do
    devices
    |> Enum.reduce([], fn device, notifications ->
      case build_notification(device, message, payload, opts) do
        nil -> notifications
        notification -> [notification | notifications]
      end
    end)
    |> Enum.reverse()
  end

  defp build_notification(%User.Device{platform: platform, token: token}, message, payload, opts) do
    case platform do
      "ios" ->
        build_apns_notification(token, message, payload)
        |> apply_options(Keyword.merge(default_apns_options(), opts))

      "android" ->
        build_fcm_notification(token, nil, message, payload)
        |> apply_options(opts)

      _ ->
        nil
    end
  end

  defp build_apns_notification(token, message, payload) do
    Pigeon.APNS.Notification.new(message, token)
    |> Pigeon.APNS.Notification.put_custom(payload)
  end

  defp build_fcm_notification(reg_id, title, body, payload) do
    notification =
      %{body: body, title: title}
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.into(%{})

    Pigeon.FCM.Notification.new(reg_id, notification, payload)
  end

  defp apply_options(notification, opts) do
    Enum.reduce(opts, notification, fn {key, value}, notification ->
      apply_option(notification, key, value)
    end)
  end

  defp apply_option(notification, _, nil), do: notification

  defp apply_option(%Pigeon.FCM.Notification{} = notification, :collapse_id, collapse_id) do
    Pigeon.FCM.Notification.put_collapse_key(notification, collapse_id)
  end

  defp apply_option(%Pigeon.FCM.Notification{} = notification, :expires_at, expires_at) do
    ttl = Timex.diff(expires_at, DateTime.utc_now(), :seconds)
    Pigeon.FCM.Notification.put_time_to_live(notification, ttl)
  end

  defp apply_option(%Pigeon.APNS.Notification{} = notification, :collapse_id, collapse_id) do
    %Pigeon.APNS.Notification{notification | collapse_id: collapse_id}
  end

  defp apply_option(%Pigeon.APNS.Notification{} = notification, :topic, topic) do
    %Pigeon.APNS.Notification{notification | topic: topic}
  end

  defp apply_option(%Pigeon.APNS.Notification{} = notification, :badge, badge) do
    Pigeon.APNS.Notification.put_badge(notification, badge)
  end

  defp apply_option(%Pigeon.APNS.Notification{} = notification, :sound, sound) do
    Pigeon.APNS.Notification.put_sound(notification, sound)
  end

  defp apply_option(%Pigeon.APNS.Notification{} = notification, :expires_at, expires_at) do
    expiration = DateTime.to_unix(expires_at, :second)
    %Pigeon.APNS.Notification{notification | expiration: expiration}
  end

  defp apply_option(notification, _, _), do: notification

  defp collapse_id(data) do
    Base.encode64(:crypto.hash(:md5, :erlang.term_to_binary(data)), padding: false)
  end

  defp apply_payload_opts(payload, payload: additional_payload) do
    Map.merge(payload, additional_payload)
  end

  defp apply_payload_opts(payload, _), do: payload

  defp apply_receiver_payload_opts(payload, %{id: receiver_id}, notification_ids: notification_ids) do
    case notification_ids do
      %{^receiver_id => notification_id} ->
        Map.put(payload, "notification_id", notification_id)

      _ ->
        payload
    end
  end

  defp apply_receiver_payload_opts(payload, _, _), do: payload

  def post_notifications(
        %{
          post: %Post{type: "event", events: [event | _]} = _post,
          receivers: receivers
        },
        opts \\ []
      ) do

    hours_until_event = round(DateTime.diff(event.date, DateTime.utc_now()) / 3600)
    message = "#{event.title} starts in about #{hours_until_event} hours."

    payload = %{
      "type" => "event:approaching",
      "event" => %{
        "id" => event.id,
        "title" => event.title,
        "event_date" => event.date
      }
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def post_upvote_notifications(
        %Post.Upvote{
          user: %User{id: upvoter_id, username: liker_username},
          post: %Post{
            id: post_id,
            title: title,
            type: post_type,
            author: %User{id: author_id, devices: devices}
          }
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{liker_username} liked your post #{title}",
      apply_payload_opts(
        %{
          "type" => "posts:liked",
          "post" => %{
            "id" => post_id,
            "type" => post_type
          }
        },
        opts
      ),
      collapse_id: collapse_id(["posts:reaction", post_id, upvoter_id]),
      badge: Notifications.unread_count(author_id)
    )
  end

  def post_comment_notifications(
        %Post.Comment{
          author: %User{username: commenter_username},
          body: comment_body,
          post: %Post{
            id: post_id,
            type: post_type,
            author: %User{id: receiver_id, devices: devices}
          }
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{commenter_username} commented on your post: #{comment_body}",
      apply_payload_opts(
        %{
          "type" => "posts:commented",
          "post" => %{
            "id" => post_id,
            "type" => post_type
          }
        },
        opts
      ),
      badge: Notifications.unread_count(receiver_id)
    )
  end

  def post_comment_upvote_notifications(
        %Post.Comment.Upvote{
          user: %User{id: liker_id, username: liker_username},
          comment: %Post.Comment{
            id: comment_id,
            post_id: post_id,
            author: %User{id: author_id, devices: devices}
          }
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{liker_username} liked your post comment",
      apply_payload_opts(
        %{
          "type" => "post:comments:liked",
          "comment" => %{"id" => comment_id},
          "post" => %{"id" => post_id}
        },
        opts
      ),
      collapse_id: collapse_id(["post:comments:reaction", comment_id, liker_id]),
      badge: Notifications.unread_count(author_id)
    )
  end

  def post_approval_request_notifications(
        %Post.ApprovalRequest{
          approver: %User{id: approver_id, devices: devices},
          requester: %User{id: requester_id, username: requester_username},
          post_id: post_id
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{requester_username} requested your approval for a post",
      apply_payload_opts(
        %{
          "type" => "post:approve:request",
          "request" => %{
            "post_id" => post_id,
            "requester" => %{
              "id" => requester_id,
              "username" => requester_username
            }
          }
        },
        opts
      ),
      badge: Notifications.unread_count(approver_id)
    )
  end

  def post_approval_request_rejection_notifications(
        %Post.ApprovalRequest.Rejection{
          approver: %User{id: approver_id, username: approver_username},
          requester: %User{id: requester_id, devices: devices},
          post_id: post_id
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{approver_username} rejected your post",
      apply_payload_opts(
        %{
          "type" => "post:approve:request:reject",
          "rejection" => %{
            "post_id" => post_id,
            "approver" => %{
              "id" => approver_id,
              "username" => approver_username
            }
          }
        },
        opts
      ),
      badge: Notifications.unread_count(requester_id)
    )
  end

  def dropchat_privilege_request_notifications(
        [
          request: %Chat.Room.ElevatedPrivilege.Request{
            id: request_id,
            user: %User{id: requester_id, username: requester_username}
          },
          receivers: receivers
        ],
        opts \\ []
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

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)
      notifications ++ build_notifications(devices, message, payload, badge: unread_count)
    end)
  end

  def dropchat_privilege_granted_notifications(
        %Chat.Room.ElevatedPrivilege{
          dropchat: %Chat.Room{id: room_id, title: room_title},
          user: %User{id: user_id, devices: devices}
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "You've been granted access to post in #{room_title}!",
      apply_payload_opts(
        %{
          "type" => "chats:privilege:granted",
          "room" => %{
            "id" => room_id,
            "title" => room_title
          }
        },
        opts
      ),
      badge: Notifications.unread_count(user_id)
    )
  end

  def chat_tagged_notifications(
        %{
          tagger: %User{username: tagger_username},
          message: %Chat.Message{message: message},
          room: %Chat.Room{key: chat_key, chat_type: chat_type, title: room_title},
          receivers: receivers
        },
        opts \\ []
      )
      when is_list(receivers) do
    message = "#{tagger_username} tagged you in #{room_title}: #{message}"

    payload = %{
      "type" => "chats:message:tagged",
      "chat" => %{
        "type" => chat_type,
        "key" => chat_key
      }
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)
      notifications ++ build_notifications(devices, message, payload, badge: unread_count)
    end)
  end

  def chat_reply_notifications(
        [
          sender: %User{username: sender_username},
          replied_to_message: %Chat.Message{user: %User{id: user_id, devices: devices}},
          reply: %Chat.Message{message: message},
          room: %Chat.Room{chat_type: chat_type, key: chat_key},
          muted?: _
        ],
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{sender_username} replied to you: #{message}",
      apply_payload_opts(
        %{
          "type" => "chats:message:reply",
          "chat" => %{
            "type" => chat_type,
            "key" => chat_key
          }
        },
        opts
      ),
      badge: Notifications.unread_count(user_id)
    )
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

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices}, unread_count}, notifications ->
      notifications ++ build_notifications(devices, message, payload, badge: unread_count)
    end)
  end

  def matching_event_interests_notifications(
        [
          event: %Event{id: event_id, title: event_title},
          receivers: receivers
        ],
        opts \\ []
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

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)
      notifications ++ build_notifications(devices, message, payload, badge: unread_count)
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

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices}, unread_count}, notifications ->
      notifications ++ build_notifications(devices, message, payload, badge: unread_count)
    end)
  end

  def new_following_notifications(
        %User.Followings.Following{
          id: following_id,
          to: %User{id: user_id, devices: devices},
          from: %User{username: follower_username, id: follower_id}
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{follower_username} started following you",
      apply_payload_opts(
        %{
          "type" => "following:new",
          "following" => %{
            "id" => following_id,
            "from" => %{"id" => follower_id, "username" => follower_username}
          }
        },
        opts
      ),
      collapse_id: collapse_id(["following:new", follower_id]),
      badge: Notifications.unread_count(user_id)
    )
  end

  def poll_vote_notifications(
        %PollItem.Vote{
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
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{voter_username} voted on your poll #{post_title}",
      apply_payload_opts(
        %{
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
        },
        opts
      ),
      collapse_id: collapse_id(["poll_vote:new", poll_id, voter_id]),
      badge: Notifications.unread_count(user_id)
    )
  end

  def event_attending_notifications(
        %Event.Attendant{
          event: %Event{
            id: event_id,
            title: event_title,
            post: %Post{author: %User{id: user_id, devices: devices}}
          },
          user: %User{id: attendant_id, username: attendant_username}
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{attendant_username} is going to attend your event #{event_title}",
      apply_payload_opts(
        %{
          "type" => "event:attendant:new",
          "attendant" => %{"id" => attendant_id, "username" => attendant_username},
          "event" => %{"id" => event_id, "title" => event_title}
        },
        opts
      ),
      collapse_id: collapse_id(["event:attendant:new", event_id, attendant_id]),
      badge: Notifications.unread_count(user_id)
    )
  end

  def event_approaching_notifications(
        %Event.Attendant{
          event: %Event{id: event_id, title: event_title, date: event_date},
          user: %User{id: user_id, devices: devices}
        },
        opts \\ []
      ) do
    hours_until_event = round(DateTime.diff(event_date, DateTime.utc_now()) / 3600)

    message =
      if hours_until_event >= 2 do
        "#{event_title} is approaching. It starts in about #{hours_until_event} hours."
      else
        "#{event_title} is approaching"
      end

    build_notifications(
      devices,
      message,
      apply_payload_opts(
        %{
          "type" => "event:approaching",
          "event" => %{
            "id" => event_id,
            "title" => event_title,
            "event_date" => event_date
          }
        },
        opts
      ),
      collapse_id: collapse_id(["event:approaching", event_id]),
      badge: Notifications.unread_count(user_id)
    )
  end

  def scheduled_area_notifications(
        %{
          template: template,
          area_notifications: area_notifications,
          receivers: receivers
        },
        opts \\ []
      ) do
    payload = %{
      "type" => "area_notifications:scheduled",
      "area_notifications" =>
        Enum.map(area_notifications, fn n ->
          %{
            "id" => n.id,
            "location" => [n.location.lat, n.location.long],
            "radius" => n.radius,
            "expires_at" => n.expires_at,
            "linked_post_id" => n.linked_post_id
          }
        end)
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          template,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def notify_location_reward(
    %Notification{
      verb: type,
      description: message,
      recipient_id: user_id
    },
    devices,
    opts \\ []
  ) do
    build_notifications(
      devices,
      message,
      apply_payload_opts(
        %{
          "type" => type
        },
        opts
      ),
      badge: Notifications.unread_count(user_id)
    )
  end

  def dropchat_created_notifications(
        %{
          admin_user: %User{username: admin_username},
          room: %Chat.Room{title: room_title} = room,
          receivers: receivers
        },
        opts \\ []
      ) do
    message =
      if room_title do
        "#{admin_username} started a dropchat room about \"#{room_title}\""
      else
        "#{admin_username} started a dropchat room"
      end

    payload = %{
      "type" => "dropchats:new:followed",
      "dropchat" => %{
        "id" => room.id,
        "key" => room.key,
        "title" => room.title
      }
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def user_access_granted_notifications(%{user: %{id: user_id, devices: devices}}, opts \\ []) do
    build_notifications(
      devices,
      "Howdy! You are now in. Come join us on BillBored",
      apply_payload_opts(
        %{
          "type" => "access:granted"
        },
        opts
      ),
      badge: Notifications.unread_count(user_id)
    )
  end

  def dropchat_stream_started_notifications(
        %{
          admin_user: %User{username: admin_username},
          stream: stream,
          room_key: room_key,
          receivers: receivers
        },
        opts \\ []
      ) do
    message =
      if stream.title do
        "#{admin_username} started a dropchat stream about \"#{stream.title}\""
      else
        "#{admin_username} started a dropchat stream"
      end

    payload = %{
      "type" => "dropchats:streams:new:followed",
      "dropchat" => %{
        "id" => stream.dropchat_id,
        "key" => room_key,
        "stream" => %{
          "title" => stream.title
        }
      }
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def dropchat_stream_pinged(
        %{
          stream: stream,
          pinger_user: %{username: pinger_username},
          pinged_user: %{id: user_id, devices: devices}
        },
        opts \\ []
      ) do
    build_notifications(
      devices,
      "#{pinger_username} recommends you a dropchat stream about \"#{stream.title}\"",
      apply_payload_opts(
        %{
          "type" => "dropchats:streams:recommendation",
          "dropchat" => %{
            "id" => stream.dropchat_id,
            "key" => stream.dropchat.key,
            "stream" => %{
              "title" => stream.title
            }
          }
        },
        opts
      ),
      notification_opts(opts, badge: Notifications.unread_count(user_id))
    )
  end

  def encourage_winning_team_notifications(
        %{
          university: university_name,
          receivers: receivers,
          diff_points: _diff_points
        },
        opts \\ []
      ) do
    message = "#{university_name} is only a few points away from winning over your team! Will you let them?"

    payload = %{
      "type" => "leaderboard:encourage"
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def encourage_opposite_team_notifications(
        %{
          university: university_name,
          receivers: receivers,
          diff_points: diff_points
        },
        opts \\ []
      ) do
    message = "#{university_name} teams gained #{diff_points / 10} more points than your team today. Will you let them win over you? Go live!"

    payload = %{
      "type" => "leaderboard:encourage"
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def user_passed_leaderboard_notifications(
        %{
          user: %User{username: username},
          receivers: receivers
        },
        opts \\ []
      ) do
    message = "#{username} just passed your points. Will you let him win over you? Go live!"

    payload = %{
      "type" => "leaderboard:updated"
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def team_passed_leaderboard_notifications(
        %{
          team: %User{username: username},
          receivers: receivers
        },
        opts \\ []
      ) do
    message = "Team_#{username} just passed your team points. Will you let them win over you? Go live!"

    payload = %{
      "type" => "leaderboard:updated"
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def university_passed_leaderboard_notifications(
        %{
          university: university,
          receivers: receivers
        },
        opts \\ []
      ) do
    message = "#{university.name} just passed your university points. Will you let them win over you? Go live!"

    payload = %{
      "type" => "leaderboard:updated"
    }

    Notifications.zip_users_with_unread_counts(receivers)
    |> Enum.reduce([], fn {%{devices: devices} = receiver, unread_count}, notifications ->
      payload = apply_receiver_payload_opts(payload, receiver, opts)

      notifications ++
        build_notifications(
          devices,
          message,
          payload,
          notification_opts(opts, badge: unread_count)
        )
    end)
  end

  def user_points_changed(
    %Notification{
      verb: type,
      description: message,
      recipient_id: user_id
    },
    devices,
    opts \\ []
  ) do
    build_notifications(
      devices,
      message,
      apply_payload_opts(
        %{
          "type" => type
        },
        opts
      ),
      badge: Notifications.unread_count(user_id)
    )
  end

  defp notification_opts(opts, default_opts) do
    Keyword.merge(default_opts, Keyword.take(opts, [:expires_at]))
  end
end
