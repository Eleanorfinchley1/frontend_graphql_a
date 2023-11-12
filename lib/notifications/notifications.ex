defmodule Notifications do
  @moduledoc false
  alias Notifications.Template
  alias BillBored.{Post, User, University, Chat, Poll, PollItem, Event, UserPoint.Audit, AnticipationCandidate}
  alias BillBored.Chat.Room.DropchatStream

  import Ecto.Query

  # TODO test
  @doc """
  Represents a notification we send when someone like a post
  belonging to a user
  """
  def process_post_push_notifications(receivers, %Post{type: "event", events: [_event | _]} = post) do
    push_receivers = Enum.filter(receivers, fn user -> user.enable_push_notifications end)

    %{
      post: post,
      receivers: push_receivers
    }
    |> Template.post_notifications()
    |> enqueue_push_job()
  end

  def process_post_push_notifications(_receivers, %Post{} = _post), do: nil

  def process_post_upvote(
        %Post.Upvote{
          post: %Post{
            author: %User{
              id: author_id,
              enable_push_notifications: enable_push_notifications
            }
          },
          user_id: upvoter_id
        } = upvote
      ) do
    unless author_id == upvoter_id do
      {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(upvote)

      if enable_push_notifications do
        upvote
        |> Template.post_upvote_notifications(payload: %{"notification_id" => notification_id})
        |> enqueue_push_job()
      end
    end

    :ok
  end

  # TODO test
  def process_post_downvote(
        %Post.Downvote{
          post: %Post{author_id: author_id},
          user_id: downvoter_id
        } = downvote
      ) do
    unless author_id == downvoter_id do
      BillBored.Notifications.create_for(downvote)
    end

    :ok
  end

  # TODO test
  @doc "if within 20 km of a user, a post gets up to 300 likes + dislike combined or 250 comments send anotification to users that are around"
  def process_popular_post(post: post, receivers: receivers) do
    Web.NotificationChannel.notify_of(:new_popular_post, post, receivers)
    BillBored.Notifications.create_for(:new_popular_post, post, receivers)

    :ok
  end

  # TODO test
  @doc "When a dropchat near a user is getting more than 1000 messages"
  def process_popular_dropchat(room: room, receivers: receivers) do
    Web.NotificationChannel.notify_of(:new_popular_dropchat, room, receivers)
    BillBored.Notifications.create_for(:new_popular_dropchat, room, receivers)

    :ok
  end

  # TODO test
  @doc """
  Represents a notification we send when someone comments on a post
  belonging to a user
  """
  def process_post_comment(
        %Post.Comment{
          author: %User{
            id: comment_author_id,
            enable_push_notifications: enable_push_notifications
          },
          post: %Post{author_id: post_author_id}
        } = comment
      ) do
    unless comment_author_id == post_author_id do
      Web.NotificationChannel.notify_of_post_comment(comment)
      {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(comment)

      if enable_push_notifications do
        comment
        |> Template.post_comment_notifications(payload: %{"notification_id" => notification_id})
        |> enqueue_push_job()
      end
    end

    :ok
  end

  # TODO test
  @doc """
  Represents a notification we send when someone like a post comment belonging
  to a user
  """
  def process_post_comment_upvote(
        %Post.Comment.Upvote{
          comment: %Post.Comment{
            author: %User{
              id: comment_author_id,
              enable_push_notifications: enable_push_notifications
            }
          },
          user_id: upvoter_id
        } = upvote
      ) do
    unless comment_author_id == upvoter_id do
      {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(upvote)

      if enable_push_notifications do
        upvote
        |> Template.post_comment_upvote_notifications(
          payload: %{"notification_id" => notification_id}
        )
        |> enqueue_push_job()
      end
    end

    :ok
  end

  # TODO test
  def process_post_comment_downvote(
        %Post.Comment.Downvote{
          comment: %Post.Comment{
            author_id: comment_author_id
          },
          user_id: downvoter_id
        } = downvote
      ) do
    unless comment_author_id == downvoter_id do
      BillBored.Notifications.create_for(downvote)
    end

    :ok
  end

  # TODO test
  @doc """
  Represents a push notification we send when someone requests a business post approval
  """
  def process_post_approval_request(
        %Post.ApprovalRequest{
          approver: %User{enable_push_notifications: enable_push_notifications}
        } = request
      ) do
    :ok = Web.NotificationChannel.notify_of(request)
    {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(request)

    if enable_push_notifications do
      request
      |> Template.post_approval_request_notifications(
        payload: %{"notification_id" => notification_id}
      )
      |> enqueue_push_job()
    end
  end

  # TODO test
  @doc """
  Represents a push notification we send when someone requests a business post approval
  """
  def process_post_approval_request_rejection(
        %Post.ApprovalRequest.Rejection{
          requester: %User{enable_push_notifications: enable_push_notifications}
        } = rejection
      ) do
    Web.NotificationChannel.notify_of(rejection)
    {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(rejection)

    if enable_push_notifications do
      rejection
      |> Template.post_approval_request_rejection_notifications(
        payload: %{"notification_id" => notification_id}
      )
      |> enqueue_push_job()
    end
  end

  # TODO test
  @doc """
  Represents a push notification we send when someone requests
  a dropchat write privilege in a dropchat where the receiver is an admin
  """
  def process_dropchat_privilege_request(
        %Chat.Room.ElevatedPrivilege.Request{
          id: request_id,
          user: requester,
          room: %Chat.Room{id: room_id, administrators: receivers}
        } = request
      )
      when is_list(receivers) do
    {_, notifications} = BillBored.Notifications.create_for(request)

    Template.dropchat_privilege_request_notifications(
      [
        request: request,
        receivers: Enum.filter(receivers, & &1.enable_push_notifications)
      ],
      receiver_opts(notifications)
    )
    |> enqueue_push_job()

    payload = %{
      "id" => request_id,
      "user" => Web.UserView.render("user.json", %{user: requester}),
      "room" => %{"id" => room_id}
    }

    Enum.each(receivers, fn receiver ->
      Web.Endpoint.broadcast("rooms:#{receiver.id}", "chats:privilege:request", payload)
    end)
  end

  # TODO test
  @doc "Represents a push notification we send when the receiver gets granted with a dropchat privilege"
  def process_dropchat_privilege_granted(
        %Chat.Room.ElevatedPrivilege{
          dropchat: %Chat.Room{key: room_key, id: dropchat_id},
          user: %User{id: user_id, enable_push_notifications: enable_push_notifications}
        } = privilege
      ) do
    {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(privilege)

    if enable_push_notifications do
      privilege
      |> Template.dropchat_privilege_granted_notifications(
        payload: %{"notification_id" => notification_id}
      )
      |> enqueue_push_job()
    end

    Web.Endpoint.broadcast("rooms:#{user_id}", "chats:privilege:granted", %{
      "room_id" => dropchat_id
    })

    Web.Endpoint.broadcast("dropchats:#{room_key}", "privilege:granted", %{user_id: user_id})

    :ok
  end

  def process_dropchat_created(admin_user, %Chat.Room{} = room, receivers) do
    push_receivers = Enum.filter(receivers, fn user -> user.enable_push_notifications end)

    {_, notifications} =
      BillBored.Notifications.create_for(
        {:dropchat_created,
         %{
           admin_user: admin_user,
           room: room,
           receivers: push_receivers
         }}
      )

    %{
      admin_user: admin_user,
      room: room,
      receivers: push_receivers
    }
    |> Template.dropchat_created_notifications(receiver_opts(notifications))
    |> enqueue_push_job()
  end

  # TODO test, also test muted
  @doc "Represents a notification we send when someone tags a user in a chat message"
  def process_chat_tagged(
        [tagger: %User{id: tagger_id}, message: _, room: _, receivers: receivers] = opts
      ) do
    opts = Map.new(opts)

    {_, notifications} =
      BillBored.Notifications.create_for(
        {:chat_tagged,
         %{
           opts
           | receivers:
               receivers
               |> Enum.map(& &1.user)
               |> Enum.reject(fn user -> tagger_id == user.id end)
         }}
      )

    receivers
    |> Enum.filter(fn %Chat.Room.Membership{
                        muted?: muted?,
                        user: %User{
                          id: receiver_id,
                          enable_push_notifications: enable_push_notifications
                        }
                      } ->
      enable_push_notifications and not muted? and tagger_id != receiver_id
    end)
    |> Enum.map(& &1.user)
    |> case do
      [] ->
        :ok

      push_notification_receivers ->
        %{opts | receivers: push_notification_receivers}
        |> Template.chat_tagged_notifications(receiver_opts(notifications))
        |> enqueue_push_job()
    end

    :ok
  end

  # TODO test, also test muted
  @doc "Represents a notification we send when someone replies to a user's message"
  def process_chat_reply(
        [
          sender: %User{id: sender_id},
          replied_to_message: %Chat.Message{
            user: %User{id: receiver_id, enable_push_notifications: enable_push_notifications}
          },
          reply: _,
          room: _,
          muted?: muted?
        ] = opts
      ) do
    unless sender_id == receiver_id do
      {:ok, %{id: notification_id}} = BillBored.Notifications.create_for({:chat_reply, opts})

      if enable_push_notifications and not muted? do
        opts
        |> Template.chat_reply_notifications(payload: %{"notification_id" => notification_id})
        |> enqueue_push_job()
      end
    end

    :ok
  end

  # TODO test, also test muted
  @doc """
  Represents a notification we send when someone posts a message in a chat room the receiver is a member of
  """
  def process_chat_message(
        [sender: %User{id: sender_id}, message: _, room: _, receivers: receivers] = opts
      ) do
    opts = Map.new(opts)

    %{opts | receivers: Enum.reject(receivers, fn user -> user.id == sender_id end)}
    |> Template.chat_message_notifications()
    |> enqueue_push_job()
  end

  # TODO test
  @doc "if an event category or tags match at least one of the interests of the user, within the defined radius (default:20km) send an apn to to that user"
  def process_matching_event_interests(
        event: %Event{post: %Post{author_id: post_author_id}} = event,
        receivers: receivers
      ) do
    receivers = Enum.reject(receivers, fn user -> user.id == post_author_id end)

    {_, notifications} =
      BillBored.Notifications.create_for(
        {:event_matching_interests, event: event, receivers: receivers}
      )

    receivers
    |> Enum.filter(& &1.enable_push_notifications)
    |> case do
      [] ->
        :ok

      push_notification_receivers ->
        Template.matching_event_interests_notifications(
          [
            event: event,
            receivers: push_notification_receivers
          ],
          receiver_opts(notifications)
        )
        |> enqueue_push_job()
    end

    :ok
  end

  # TODO test
  @doc "if a friend of user starts a livestream, send a notification"
  def process_published_livestream([livestream: _, receivers: _] = opts) do
    opts
    |> Template.published_livestream_notifications()
    |> enqueue_push_job()
  end

  # TODO test
  @doc "When someone follows you"
  def process_new_following(
        %User.Followings.Following{
          to: %User{enable_push_notifications: enable_push_notifications}
        } = following
      ) do
    {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(following)

    if enable_push_notifications do
      following
      |> Template.new_following_notifications(payload: %{"notification_id" => notification_id})
      |> enqueue_push_job()
    end

    :ok
  end

  # TODO test
  @doc "when someone gives a poll to a poll-post"
  def process_poll_vote(
        %PollItem.Vote{
          poll_item: %PollItem{
            poll: %Poll{
              post: %Post{
                author: %User{id: author_id, enable_push_notifications: enable_push_notifications}
              }
            }
          },
          user_id: voter_id
        } = vote
      ) do
    unless voter_id == author_id do
      {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(vote)

      if enable_push_notifications do
        vote
        |> Template.poll_vote_notifications(payload: %{"notification_id" => notification_id})
        |> enqueue_push_job()
      end
    end

    :ok
  end

  # TODO test
  @doc "when someone is going to attend an event, send a notification to the person who created the event"
  def process_event_attending(
        %Event.Attendant{
          status: "accepted",
          event: %Event{
            post: %Post{
              author: %User{id: author_id, enable_push_notifications: enable_push_notifications}
            },
            date: event_date
          },
          user: %User{id: attendant_id}
        } = attendant
      ) do
    unless attendant_id == author_id do
      {:ok, %{id: notification_id}} = BillBored.Notifications.create_for(attendant)

      if enable_push_notifications do
        attendant
        |> Template.event_attending_notifications(
          payload: %{"notification_id" => notification_id}
        )
        |> enqueue_push_job()
      end
    end

    # remind user when event is approaching send a notification to him 48hr before
    Rihanna.schedule({__MODULE__, :process_event_approaching, [attendant.id, before: 48]},
      at: DateTime.add(event_date, -48 * 60 * 60)
    )
  end

  # TODO test
  @doc "remind user when event is approaching"
  def process_event_approaching(attendant_id, {:before, before_hours})
      when is_integer(attendant_id) do
    # the user might have changed their preferences since the notifications has been scehduled
    # or the event title date have been changed
    # so we refetch it all
    Event.Attendant
    |> Repo.get(attendant_id)
    |> Repo.preload(:event, user: :devices)
    |> case do
      %Event.Attendant{
        status: "accepted",
        user: %User{enable_push_notifications: enable_push_notifications}
      } = attendant ->
        reschedule_event_approaching_notification(attendant, before_hours)

        {:ok, %{id: notification_id}} =
          BillBored.Notifications.create_for({:event_approaching, attendant})

        if enable_push_notifications do
          attendant
          |> Template.event_approaching_notifications(
            payload: %{"notification_id" => notification_id}
          )
          |> enqueue_push_job()
        end

      _other ->
        :ok
    end
  end

  defp reschedule_event_approaching_notification(attendant, before_hours) do
    %Event.Attendant{event: %Event{date: event_date}} = attendant
    hours_until_event = round(DateTime.diff(event_date, DateTime.utc_now()) / 3600)

    case {before_hours, hours_until_event} do
      {48, 48} ->
        # we notify the user again in 12 hours before the event
        Rihanna.schedule({__MODULE__, :process_event_approaching, [attendant.id]},
          at: DateTime.add(event_date, -12 * 60 * 60)
        )

      {12, 12} ->
        :ok
    end
  end

  def scheduled_area_notification(
        %{
          template: template,
          timestamp: timestamp,
          timetable_runs: timetable_runs,
          receivers: receivers
        } = args
      ) do
    {_, notifications} = BillBored.Notifications.create_for({:scheduled_area_notifications, args})

    push_receivers =
      Enum.filter(receivers, fn %{enable_push_notifications: enabled} -> enabled end)

    Enum.each(push_receivers, fn user ->
      with {:ok, user_area_notification} <-
             BillBored.Clickhouse.UserAreaNotification.build(user, timestamp) do
        BillBored.Clickhouse.UserAreaNotifications.create(user_area_notification)
      end
    end)

    area_notifications =
      Enum.map(timetable_runs, fn %{area_notification: area_notification} -> area_notification end)

    expires_at =
      area_notifications
      |> Enum.map(& &1.expires_at)
      |> Enum.reject(&is_nil(&1))
      |> Enum.max_by(&DateTime.to_unix(&1), fn -> Timex.shift(DateTime.utc_now(), days: 7) end)

    %{
      template: template,
      timestamp: timestamp,
      area_notifications: area_notifications,
      receivers: receivers
    }
    |> Template.scheduled_area_notifications(
      Keyword.merge(receiver_opts(notifications), expires_at: expires_at)
    )
    |> enqueue_push_job()

    :ok
  end

  def process_location_reward_notification(
        %{
          user: user,
          location_reward: location_reward
        } = args
      ) do

    {:ok, notification} = BillBored.Notifications.create_for({:location_reward_notifications, args})
    Template.notify_location_reward(
      notification,
      user.devices,
      expires_at: DateTime.to_unix(location_reward.ended_at)
    )
    |> enqueue_push_job()

    notification
  end

  def process_user_access_granted(%User{flags: %{"access" => "granted"}} = user) do
    with true <- user.enable_push_notifications,
         false <-
           BillBored.Notifications.user_notification_exists?(
             user.id,
             "access:granted",
             Timex.shift(Timex.now(), hours: -24)
           ) do
      {:ok, %{id: notification_id}} =
        BillBored.Notifications.create_for({:user_access_granted, user})

      %{user: user}
      |> Template.user_access_granted_notifications(
        payload: %{"notification_id" => notification_id}
      )
      |> enqueue_push_job()
    end

    :ok
  end

  def process_dropchat_stream_started(%{
        stream: %DropchatStream{} = stream,
        receivers: receivers
      }) do
    stream = stream |> Repo.preload([:admin, :dropchat])

    push_receivers =
      Enum.filter(receivers, fn %{enable_push_notifications: enabled} -> enabled end)

    {_, notifications} =
      BillBored.Notifications.create_for(
        {:dropchat_stream_started,
         %{
           admin_user: stream.admin,
           room_key: stream.dropchat.key,
           stream: stream,
           receivers: push_receivers
         }}
      )

    %{
      admin_user: stream.admin,
      room_key: stream.dropchat.key,
      stream: stream,
      receivers: push_receivers
    }
    |> Template.dropchat_stream_started_notifications(
      Keyword.merge(receiver_opts(notifications),
        expires_at: Timex.shift(DateTime.utc_now(), hours: 3)
      )
    )
    |> enqueue_push_job()

    :ok
  end

  def process_dropchat_stream_pinged(args) do
    Template.dropchat_stream_pinged(args, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
    |> enqueue_push_job()

    :ok
  end

  def process_streaming_audit(%Audit{reason: "streaming"} = audit) do
    user = user_with_devices(audit.user_id)
    case BillBored.Notifications.create_for(audit, user.university || %University{name: nil}) do
      {:ok, notification} ->
        Template.user_points_changed(notification, user.devices, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
          |> enqueue_push_job()
      _ -> nil
    end

    :ok
  end

  def encourage_winning_team(receivers, team, %{university: %{name: university_name}} = opposite) do
    {_, notifications} =
      BillBored.Notifications.create_for(
        {:encourage_winning_team,
         %{
           university: university_name,
           receivers: receivers,
           diff_points: team.daily_points - opposite.daily_points
         }}
      )

    %{
      university: university_name,
      receivers: receivers,
      diff_points: team.daily_points - opposite.daily_points
    }
    |> Template.encourage_winning_team_notifications(
      Keyword.merge(receiver_opts(notifications),
        expires_at: Timex.shift(DateTime.utc_now(), hours: 3)
      )
    )
    |> enqueue_push_job()

    :ok
  end

  def encourage_opposite_team(receivers, %{university: %{name: university_name}} = team, opposite) do
    {_, notifications} =
      BillBored.Notifications.create_for(
        {:encourage_opposite_team,
         %{
           university: university_name,
           receivers: receivers,
           diff_points: team.daily_points - opposite.daily_points
         }}
      )

    %{
      university: university_name,
      receivers: receivers,
      diff_points: team.daily_points - opposite.daily_points
    }
    |> Template.encourage_opposite_team_notifications(
      Keyword.merge(receiver_opts(notifications),
        expires_at: Timex.shift(DateTime.utc_now(), hours: 3)
      )
    )
    |> enqueue_push_job()

    :ok
  end

  def process_user_passed_leaderboard(user, receivers) do
    {_, notifications} =
      BillBored.Notifications.create_for(
        {:user_passed_leaderboard,
         %{
           user: user,
           receivers: receivers
         }}
      )

    %{
      user: user,
      receivers: receivers
    }
    |> Template.user_passed_leaderboard_notifications(
      Keyword.merge(receiver_opts(notifications),
        expires_at: Timex.shift(DateTime.utc_now(), hours: 3)
      )
    )
    |> enqueue_push_job()

    :ok
  end

  def process_team_passed_leaderboard(team, receivers) do
    {_, notifications} =
      BillBored.Notifications.create_for(
        {:team_passed_leaderboard,
         %{
           team: team,
           receivers: receivers
         }}
      )

    %{
      team: team,
      receivers: receivers
    }
    |> Template.team_passed_leaderboard_notifications(
      Keyword.merge(receiver_opts(notifications),
        expires_at: Timex.shift(DateTime.utc_now(), hours: 3)
      )
    )
    |> enqueue_push_job()

    :ok
  end

  def process_university_passed_leaderboard(university, receivers) do
    {_, notifications} =
      BillBored.Notifications.create_for(
        {:university_passed_leaderboard,
         %{
           university: university,
           receivers: receivers
         }}
      )

    %{
      university: university,
      receivers: receivers
    }
    |> Template.university_passed_leaderboard_notifications(
      Keyword.merge(receiver_opts(notifications),
        expires_at: Timex.shift(DateTime.utc_now(), hours: 3)
      )
    )
    |> enqueue_push_job()

    :ok
  end

  def process_user_point_audit(%Audit{} = audit) do
    user = user_with_devices(audit.user_id)
    case BillBored.Notifications.create_for(audit) do
      {:ok, notification} ->
        Template.user_points_changed(notification, user.devices, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
          |> enqueue_push_job()
      _ -> nil
    end

    :ok
  end

  def process_user_point_audit(%Audit{} = audit, %AnticipationCandidate{} = candidate) do
    user = user_with_devices(audit.user_id)
    case BillBored.Notifications.create_for(audit, candidate) do
      {:ok, notification} ->
        Template.user_points_changed(notification, user.devices, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
          |> enqueue_push_job()
      _ -> nil
    end

    :ok
  end

  def process_points_request(request: request, from: user, to: receiver_ids) do
    Web.NotificationChannel.notify_of(:requested_stream_points, request, user, receiver_ids)

    :ok
  end

  def process_points_donation(donation: donation, sender_audit: sender_audit, receiver_audit: receiver_audit) do
    sender = user_with_devices(donation.sender_id)
    receiver = user_with_devices(donation.receiver_id)

    case BillBored.Notifications.create_for(sender_audit, receiver) do
      {:ok, notification} ->
        Template.user_points_changed(notification, sender.devices, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
          |> enqueue_push_job()
      _ -> nil
    end

    case BillBored.Notifications.create_for(receiver_audit, sender) do
      {:ok, notification} ->
        Template.user_points_changed(notification, receiver.devices, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
          |> enqueue_push_job()
      _ -> nil
    end

    :ok
  end

  def process_consumed_donation(donation: donation, receiver_audit: receiver_audit, sender_audits: sender_audits) do
    sender = user_with_devices(donation.sender_id)
    receiver = user_with_devices(donation.receiver_id)

    case BillBored.Notifications.create_for(receiver_audit, sender) do
      {:ok, notification} ->
        Template.user_points_changed(notification, receiver.devices, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
          |> enqueue_push_job()
      _ -> nil
    end

    Enum.each(sender_audits, fn audit ->
      case BillBored.Notifications.create_for(audit, receiver) do
        {:ok, notification} ->
          Template.user_points_changed(notification, sender.devices, expires_at: Timex.shift(DateTime.utc_now(), hours: 3))
            |> enqueue_push_job()
        _ -> nil
      end
    end)

    :ok
  end

  defp user_with_devices(user_id) do
    User |> where(id: ^user_id) |> preload([:devices, :university]) |> Repo.one()
  end

  defp enqueue_push_job([]) do
    :ok
  end

  defp enqueue_push_job(notifications) do
    Rihanna.enqueue(Queue.PigeonPushJob, notifications)
  end

  defp receiver_opts(notifications) do
    notification_ids =
      notifications
      |> Enum.map(fn %{id: notification_id, recipient_id: receiver_id} ->
        {receiver_id, notification_id}
      end)
      |> Enum.into(%{})

    [notification_ids: notification_ids]
  end

  def receiver_opts(notifications, opts) do
    Keyword.merge(receiver_opts(notifications), opts)
  end
end
