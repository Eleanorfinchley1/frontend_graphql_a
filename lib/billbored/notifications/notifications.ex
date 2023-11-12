defmodule BillBored.Notifications do
  ##
  ## You can find codes for the content_types
  ## in "django_content_type" table.
  ##
  ## "accounts", "userprofile" → 9
  ## "chat", "room" → 25
  ## "pst", "post" → 13
  ## "comments", "comments" → 20
  ##

  @type_user 9
  @type_post 13
  @type_chat 25
  @type_comment 20

  import Ecto.Query
  alias BillBored.{User, UserPoints, University, Chat, Notification, Post, PollItem, Poll, Event, UserPoint.Audit, AnticipationCandidate}

  def create_for(:new_popular_post, %Post{id: post_id, title: post_title}, receivers) do
    description = "New popular post around you: #{post_title}"
    actor_id = to_string(post_id)
    action_id = to_string(post_id)
    target_id = to_string(post_id)
    timestamp = utc_now()

    Repo.insert_all(
      Notification,
      Enum.map(receivers, fn %User{id: user_id} ->
        [
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: "posts:new:popular",
          actor_id: actor_id,
          actor_type: @type_post,
          action_id: action_id,
          target_id: target_id,
          target_type: @type_post,
          timestamp: timestamp,
          unread: true,
          deleted: false,
          emailed: false
        ]
      end)
    )
  end

  def create_for(:new_popular_dropchat, %Chat.Room{key: room_key, title: room_title}, receivers) do
    description = "New popular dropchat around you: #{room_title}"
    actor_id = to_string(room_key)
    action_id = to_string(room_key)
    target_id = to_string(room_key)
    timestamp = utc_now()

    Repo.insert_all(
      Notification,
      Enum.map(receivers, fn %User{id: user_id} ->
        [
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: "dropchats:new:popular",
          actor_id: actor_id,
          actor_type: @type_chat,
          action_id: action_id,
          target_id: target_id,
          target_type: @type_chat,
          timestamp: timestamp,
          unread: true,
          deleted: false,
          emailed: false
        ]
      end)
    )
  end

  def create_for(
        {:chat_tagged,
         %{
           tagger: %User{id: tagger_id, username: tagger_username},
           message: %Chat.Message{id: message_id, message: message},
           room: %Chat.Room{key: room_key, title: room_title},
           receivers: receivers
         }}
      )
      when is_list(receivers) do
    description = "#{tagger_username} tagged you in #{room_title}: #{message}"
    actor_id = to_string(tagger_id)
    target_id = to_string(room_key)
    action_id = to_string(message_id)
    timestamp = utc_now()

    Repo.insert_all(
      Notification,
      Enum.map(receivers, fn %User{id: user_id} ->
        [
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: "chats:message:tagged",
          actor_id: actor_id,
          actor_type: @type_user,
          action_id: action_id,
          target_id: target_id,
          target_type: @type_chat,
          timestamp: timestamp,
          unread: true,
          deleted: false,
          emailed: false
        ]
      end),
      returning: [:id, :recipient_id]
    )
  end

  def create_for(
        {:chat_reply,
         sender: %User{id: sender_id, username: sender_username},
         replied_to_message: %Chat.Message{user: %User{id: recipient_id}},
         reply: %Chat.Message{id: reply_id, message: message},
         room: %Chat.Room{key: chat_key},
         muted?: _muted?}
      ) do
    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{sender_username} replied to you: #{message}",
      verb: "chats:message:reply",
      actor_id: to_string(sender_id),
      actor_type: @type_user,
      action_id: to_string(reply_id),
      target_id: to_string(chat_key),
      target_type: @type_chat,
      timestamp: utc_now()
    })
  end

  def create_for(
        {:event_matching_interests,
         event: %Event{id: event_id, title: event_title, post_id: post_id}, receivers: receivers}
      )
      when is_list(receivers) do
    description = "#{event_title} matches your interests"
    event_id = to_string(event_id)
    post_id = to_string(post_id)
    timestamp = utc_now()

    Repo.insert_all(
      Notification,
      Enum.map(receivers, fn %User{id: user_id} ->
        [
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: "events:matching_interests",
          actor_id: event_id,
          actor_type: @type_post,
          action_id: event_id,
          target_id: post_id,
          target_type: @type_post,
          timestamp: timestamp,
          unread: true,
          deleted: false,
          emailed: false
        ]
      end),
      returning: [:id, :recipient_id]
    )
  end

  def create_for(
        {:event_approaching,
         %Event.Attendant{
           event: %Event{id: event_id, post_id: post_id, title: event_title, date: event_date},
           user: %User{id: recipient_id}
         }}
      ) do
    hours_until_event = round(DateTime.diff(event_date, DateTime.utc_now()) / 3600)

    description =
      if hours_until_event >= 2 do
        "#{event_title} is approaching. It starts in about #{hours_until_event} hours."
      else
        "#{event_title} is approaching"
      end

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: description,
      verb: "event:approaching",
      actor_id: to_string(event_id),
      actor_type: @type_post,
      action_id: to_string(event_id),
      target_id: to_string(post_id),
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%User.Followings.Following{
        id: following_id,
        to: %User{id: recipient_id},
        from: %User{id: follower_id, username: follower_username}
      }) do
    target_id = to_string(follower_id)
    verb = "following:new"

    Notification
    |> where(recipient_id: ^recipient_id)
    |> where(verb: ^verb)
    |> where(target_id: ^target_id)
    |> Repo.delete_all()

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{follower_username} started following you",
      verb: verb,
      actor_id: to_string(follower_username),
      actor_type: @type_user,
      action_id: to_string(following_id),
      target_id: target_id,
      target_type: @type_user,
      timestamp: utc_now()
    })
  end

  def create_for(%PollItem.Vote{
        user: %User{id: voter_id, username: voter_username},
        poll_item: %PollItem{
          poll: %Poll{
            id: poll_id,
            post: %Post{id: post_id, title: post_title, author: %User{id: recipient_id}}
          }
        }
      }) do
    verb = "poll_vote:new"
    actor_id = to_string(voter_id)
    action_id = to_string(poll_id)
    target_id = to_string(post_id)

    Notification
    |> where(recipient_id: ^recipient_id)
    |> where(verb: ^verb)
    |> where(actor_id: ^actor_id)
    |> where(target_id: ^target_id)
    |> Repo.delete_all()

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{voter_username} voted on your poll #{post_title}",
      verb: verb,
      actor_id: actor_id,
      actor_type: @type_user,
      action_id: action_id,
      target_id: target_id,
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%Event.Attendant{
        status: "accepted",
        event: %Event{
          id: event_id,
          title: event_title,
          post: %Post{id: post_id, author: %User{id: recipient_id}}
        },
        user: %User{id: attendant_id, username: attendant_username}
      }) do
    verb = "event:attendant:new"
    actor_id = to_string(attendant_id)
    action_id = to_string(event_id)
    target_id = to_string(post_id)

    Notification
    |> where(recipient_id: ^recipient_id)
    |> where(verb: ^verb)
    |> where(actor_id: ^actor_id)
    |> where(action_id: ^action_id)
    |> Repo.delete_all()

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{attendant_username} is going to attend your event #{event_title}",
      verb: verb,
      actor_id: actor_id,
      actor_type: @type_user,
      action_id: action_id,
      target_id: target_id,
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%Post.Upvote{
        id: upvote_id,
        post: %Post{id: post_id, author_id: recipient_id, title: post_title},
        user: %User{id: actor_id, username: actor_username}
      }) do
    actor_id = to_string(actor_id)
    upvote_id = to_string(upvote_id)
    post_id = to_string(post_id)

    remove_previous_post_reactions(recipient_id, actor_id, post_id)

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{actor_username} liked your post #{post_title}",
      verb: "posts:like",
      actor_id: actor_id,
      actor_type: @type_user,
      action_id: upvote_id,
      target_id: post_id,
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%Post.Downvote{
        id: downvote_id,
        post: %Post{id: post_id, author_id: recipient_id, title: post_title},
        user: %User{id: actor_id, username: actor_username}
      }) do
    actor_id = to_string(actor_id)
    downvote_id = to_string(downvote_id)
    post_id = to_string(post_id)

    remove_previous_post_reactions(recipient_id, actor_id, post_id)

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{actor_username} does not like your post #{post_title}",
      verb: "posts:reacted",
      actor_id: actor_id,
      actor_type: @type_user,
      action_id: downvote_id,
      target_id: post_id,
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%Post.Comment.Upvote{
        comment: %Post.Comment{id: comment_id, post_id: post_id, author_id: recipient_id},
        user: %User{id: actor_id, username: actor_username}
      }) do
    actor_id = to_string(actor_id)
    comment_id = to_string(comment_id)
    post_id = to_string(post_id)

    remove_previous_post_comment_reactions(recipient_id, actor_id, comment_id)

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{actor_username} liked your comment",
      verb: "post:comments:like",
      actor_id: actor_id,
      actor_type: @type_user,
      action_id: comment_id,
      target_id: post_id,
      target_type: @type_comment,
      timestamp: utc_now()
    })
  end

  def create_for(%Post.Comment.Downvote{
        comment: %Post.Comment{id: comment_id, post_id: post_id, author_id: recipient_id},
        user: %User{id: actor_id, username: actor_username}
      }) do
    actor_id = to_string(actor_id)
    comment_id = to_string(comment_id)
    post_id = to_string(post_id)

    remove_previous_post_comment_reactions(recipient_id, actor_id, comment_id)

    Repo.insert(%Notification{
      level: "info",
      recipient_id: recipient_id,
      public: false,
      description: "#{actor_username} does not like your comment",
      verb: "post:comments:reacted",
      actor_id: actor_id,
      actor_type: @type_user,
      action_id: comment_id,
      target_id: post_id,
      target_type: @type_comment,
      timestamp: utc_now()
    })
  end

  def create_for(%Post.Comment{
        id: comment_id,
        post: %Post{id: post_id, author_id: post_author_id},
        author: %User{username: comment_author_username, id: comment_author_id}
      }) do
    Repo.insert(%Notification{
      level: "info",
      recipient_id: post_author_id,
      public: false,
      description: "#{comment_author_username} commented on your post",
      verb: "posts:comment",
      actor_id: to_string(comment_author_id),
      actor_type: @type_user,
      action_id: to_string(comment_id),
      target_id: to_string(post_id),
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%Post.ApprovalRequest{} = request) do
    Repo.insert(%Notification{
      level: "info",
      recipient_id: request.approver_id,
      public: false,
      description: "#{request.requester.username} requested your approval for a post",
      verb: "posts:approve:request",
      actor_id: to_string(request.requester.id),
      actor_type: @type_user,
      action_id: to_string(request.post_id),
      target_id: to_string(request.post_id),
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%Post.ApprovalRequest.Rejection{} = rejection) do
    Repo.insert(%Notification{
      level: "info",
      recipient_id: rejection.requester_id,
      public: false,
      description: "#{rejection.approver.username} rejected your post",
      verb: "posts:approve:request:reject",
      actor_id: to_string(rejection.approver.id),
      actor_type: @type_user,
      action_id: to_string(rejection.post_id),
      target_id: to_string(rejection.post_id),
      target_type: @type_post,
      timestamp: utc_now()
    })
  end

  def create_for(%Chat.Room.ElevatedPrivilege{
        user: %User{} = user,
        dropchat: %Chat.Room{title: title, key: dropchat_key}
      }) do
    Repo.insert(%Notification{
      level: "info",
      recipient: user,
      public: false,
      description: "you've been given write access in dropchat #{title}",
      verb: "chats:privilege:granted",
      target_id: to_string(dropchat_key),
      actor_type: @type_user,
      target_type: @type_chat,
      timestamp: utc_now()
    })
  end

  def create_for(%Chat.Room.ElevatedPrivilege.Request{
        id: request_id,
        user: %User{username: requester_username, id: requester_id},
        room: %Chat.Room{title: room_title, key: room_key, administrators: admins}
      }) do
    Repo.insert_all(
      Notification,
      Enum.map(admins, fn admin ->
        [
          level: "info",
          recipient_id: admin.id,
          public: false,
          description: "#{requester_username} requested write access in dropchat #{room_title}",
          verb: "chats:privilege:request",
          actor_id: to_string(requester_id),
          actor_type: @type_user,
          action_id: to_string(request_id),
          target_id: to_string(room_key),
          target_type: @type_chat,
          timestamp: utc_now(),
          unread: true,
          deleted: false,
          emailed: false
        ]
      end),
      returning: [:id, :recipient_id]
    )
  end

  def create_for({:scheduled_area_notifications,
    %{
      template: template,
      timetable_runs: timetable_runs,
      receivers: receivers
    }}) do
      now = utc_now()

      result =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:insert_notifications, fn _, _ ->
          result = Repo.insert_all(
            Notification,
            Enum.map(receivers, fn %{id: user_id} ->
              [
                level: "info",
                recipient_id: user_id,
                public: false,
                description: template,
                verb: "area_notifications:scheduled",
                actor_id: to_string(user_id),
                actor_type: @type_user,
                timestamp: now,
                unread: true,
                deleted: false,
                emailed: false
              ]
            end),
            returning: [:id, :recipient_id]
          )

          {:ok, result}
        end)
        |> Ecto.Multi.run(:insert_notification_area_notifications, fn _, %{insert_notifications: {_, notifications}} ->
          notifications_by_user_id = Enum.map(notifications, (&({&1.recipient_id, &1}))) |> Enum.into(%{})

          {_, inserted} = Repo.insert_all(
            BillBored.Notifications.NotificationAreaNotification,
            Enum.flat_map(receivers, fn %{id: user_id} ->
              notification_id = notifications_by_user_id[user_id].id

              Enum.map(timetable_runs, fn %{id: timetable_run_id, area_notification: %{id: area_notification_id}} ->
                [
                  notification_id: notification_id,
                  area_notification_id: area_notification_id,
                  timetable_run_id: timetable_run_id,
                  inserted_at: now
                ]
              end)
            end)
          )

          {:ok, inserted}
        end)
        |> Repo.transaction()

    with {:ok, %{insert_notifications: result}} <- result do
      result
    end
  end

  def create_for({:location_reward_notifications, %{
    user: user,
    location_reward: location_reward
  }}) do
    description = "Please do stream at the place near lat:#{location_reward.location.lat} long:#{location_reward.location.long}) to earn #{location_reward.stream_points} streaming points between #{location_reward.started_at} and #{location_reward.ended_at}"

    Repo.insert(%Notification{
      level: "info",
      recipient_id: user.id,
      public: false,
      description: description,
      verb: "location_reward:notify",
      actor_id: to_string(user.id),
      actor_type: @type_user,
      target_id: to_string(user.id),
      target_type: @type_user,
      timestamp: DateTime.utc_now()
    })
  end

  def create_for({:dropchat_created, %{
    admin_user: admin_user,
    room: %{title: room_title, key: room_key},
    receivers: receivers
  }}) do
    description = if room_title do
      "#{admin_user.username} started a dropchat room about \"#{room_title}\""
    else
      "#{admin_user.username} started a dropchat room"
    end

    actor_id = to_string(room_key)
    action_id = to_string(room_key)
    target_id = to_string(room_key)
    timestamp = utc_now()

    Repo.insert_all(
      Notification,
      Enum.map(receivers, fn %User{id: user_id} ->
        [
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: "dropchats:new:followed",
          actor_id: actor_id,
          actor_type: @type_chat,
          action_id: action_id,
          target_id: target_id,
          target_type: @type_chat,
          timestamp: timestamp,
          unread: true,
          deleted: false,
          emailed: false
        ]
      end),
      returning: [:id, :recipient_id]
    )
  end

  def create_for({:user_access_granted, user}) do
    Repo.insert(%Notification{
      level: "info",
      recipient_id: user.id,
      public: false,
      description: "Howdy! You are now in. Come join us on BillBored",
      verb: "access:granted",
      actor_id: to_string(user.id),
      actor_type: @type_user,
      target_id: to_string(user.id),
      target_type: @type_user,
      timestamp: utc_now()
    })
  end

  def create_for({:dropchat_stream_started, %{admin_user: admin_user, room_key: room_key, stream: stream, receivers: receivers}}) do
    description = "#{admin_user.username} started a dropchat stream about \"#{stream.title}\""

    actor_id = to_string(admin_user.id)
    action_id = to_string(room_key)
    target_id = to_string(room_key)
    timestamp = utc_now()

    Repo.insert_all(
      Notification,
      Enum.map(receivers, fn %User{id: user_id} ->
        [
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: "dropchats:streams:new:followed",
          actor_id: actor_id,
          actor_type: @type_user,
          action_id: action_id,
          target_id: target_id,
          target_type: @type_chat,
          timestamp: timestamp,
          unread: true,
          deleted: false,
          emailed: false
        ]
      end),
      returning: [:id, :recipient_id]
    )
  end

  def create_for({:encourage_winning_team, %{university: university_name,
           receivers: receivers,
           diff_points: _diff_points}}) do
    description = "#{university_name} is only a few points away from winning over your team! Will you let them?"

    receivers
    |> Enum.map(fn %User{id: user_id} ->
      [
        level: "info",
        recipient_id: user_id,
        public: false,
        description: description,
        verb: "leaderboard:encourage",
        actor_id: to_string(user_id),
        actor_type: @type_user,
        action_id: to_string(user_id),
        target_id: to_string(user_id),
        target_type: @type_user,
        timestamp: utc_now(),
        unread: true,
        deleted: false,
        emailed: false
      ]
    end)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce([], fn chunk, notifications ->
      {_inserted_count, rows} = Repo.insert_all(Notification, chunk, returning: [:id, :recipient_id])
      notifications ++ rows
    end)
  end

  def create_for({:encourage_opposite_team, %{university: university_name,
           receivers: receivers,
           diff_points: diff_points}}) do
    description = "#{university_name} teams gained #{diff_points / 10} more points than your team today. Will you let them win over you? Go live!"

    receivers
    |> Enum.map(fn %User{id: user_id} ->
      [
        level: "info",
        recipient_id: user_id,
        public: false,
        description: description,
        verb: "leaderboard:encourage",
        actor_id: to_string(user_id),
        actor_type: @type_user,
        action_id: to_string(user_id),
        target_id: to_string(user_id),
        target_type: @type_user,
        timestamp: utc_now(),
        unread: true,
        deleted: false,
        emailed: false
      ]
    end)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce([], fn chunk, notifications ->
      {_inserted_count, rows} = Repo.insert_all(Notification, chunk, returning: [:id, :recipient_id])
      notifications ++ rows
    end)
  end

  def create_for({:user_passed_leaderboard, %{user: user, receivers: receivers}}) do
    description = "#{user.username} just passed your points. Will you let him win over you? Go live!"

    receivers
    |> Enum.map(fn %User{id: user_id} ->
      [
        level: "info",
        recipient_id: user_id,
        public: false,
        description: description,
        verb: "leaderboard:changed",
        actor_id: to_string(user.id),
        actor_type: @type_user,
        action_id: to_string(user.id),
        target_id: to_string(user_id),
        target_type: @type_user,
        timestamp: utc_now(),
        unread: true,
        deleted: false,
        emailed: false
      ]
    end)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce([], fn chunk, notifications ->
      {_inserted_count, rows} = Repo.insert_all(Notification, chunk, returning: [:id, :recipient_id])
      notifications ++ rows
    end)
  end

  def create_for({:team_passed_leaderboard, %{team: team, receivers: receivers}}) do
    description = "Team_#{team.username} just passed your team points. Will you let them win over you? Go live!"

    receivers
    |> Enum.map(fn %User{id: user_id} ->
      [
        level: "info",
        recipient_id: user_id,
        public: false,
        description: description,
        verb: "leaderboard:changed",
        actor_id: to_string(team.id),
        actor_type: @type_user,
        action_id: to_string(team.id),
        target_id: to_string(user_id),
        target_type: @type_user,
        timestamp: utc_now(),
        unread: true,
        deleted: false,
        emailed: false
      ]
    end)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce([], fn chunk, notifications ->
      {_inserted_count, rows} = Repo.insert_all(Notification, chunk, returning: [:id, :recipient_id])
      notifications ++ rows
    end)
  end

  def create_for({:university_passed_leaderboard, %{university: university, receivers: receivers}}) do
    description = "#{university.name} just passed your university points. Will you let them win over you? Go live!"

    receivers
    |> Enum.map(fn %User{id: user_id} ->
      [
        level: "info",
        recipient_id: user_id,
        public: false,
        description: description,
        verb: "leaderboard:changed",
        actor_id: to_string(user_id),
        actor_type: @type_user,
        action_id: to_string(user_id),
        target_id: to_string(user_id),
        target_type: @type_user,
        timestamp: utc_now(),
        unread: true,
        deleted: false,
        emailed: false
      ]
    end)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce([], fn chunk, notifications ->
      {_inserted_count, rows} = Repo.insert_all(Notification, chunk, returning: [:id, :recipient_id])
      notifications ++ rows
    end)
  end

  def create_for(%Audit{
    user_id: user_id,
    points: points,
    reason: reason,
    p_type: p_type,
    created_at: timestamp
  }) do
    if points != 0 do
      point_type = case p_type do
        "stream" -> "streaming points"
        "general" -> "general points"
      end
      points = abs(points)

      verb = "points:changed:#{reason}"
      remove_previous_notifications(user_id, verb)

      description = case reason do
        "signup" -> "You just got #{points / 10} #{point_type} after signning up"
        "signup_expire" -> "Just expired #{points / 10} unused #{point_type} after signning up"
        "daily" ->
          case UserPoints.daily_points() - points do
            0 -> "Just received #{UserPoints.daily_points() / 10} daily #{point_type}"
            _ -> "Just expired the unused #{(UserPoints.daily_points() - points) / 10} #{point_type} and received #{UserPoints.daily_points() / 10} daily #{point_type}"
          end
        "referral" -> "You just got #{points / 10} referral #{point_type}"
        "streaming" -> "You just used #{points / 10} #{point_type}"
        "absent" -> "You lost #{points / 10} #{point_type} due to #{get_in(Application.get_env(:billbored, BillBored.UserPoints), [:absent_days])} days of inactivity"
        "location" -> "You just got #{points / 10} location #{point_type}"
        "anticipation_double" -> "Your #{point_type} got doubled"
        "peak" -> "You just got #{points / 10} peak #{point_type}"
        _ -> nil
      end

      if not is_nil(description) do
        Repo.insert(%Notification{
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: verb,
          actor_id: to_string(user_id),
          actor_type: @type_user,
          target_id: to_string(user_id),
          target_type: @type_user,
          timestamp: timestamp || DateTime.utc_now()
        })
      end
    end
  end

  def create_for(%Audit{
    user_id: user_id,
    points: points,
    reason: reason,
    p_type: _p_type,
    created_at: timestamp
  }, %University{name: university_name}) do
    if points != 0 do
      points = abs(points)

      verb = "points:changed:#{reason}"

      description = case reason do
        "streaming" -> "Congratulations! Your stream has earned you, your team, and #{university_name || "university"}, #{points / 10} points."
        _ -> nil
      end

      if not is_nil(description) do
        Repo.insert(%Notification{
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: verb,
          actor_id: to_string(user_id),
          actor_type: @type_user,
          target_id: to_string(user_id),
          target_type: @type_user,
          timestamp: timestamp || DateTime.utc_now()
        })
      end
    end
  end

  def create_for(%Audit{
    user_id: user_id,
    points: points,
    reason: reason,
    p_type: p_type,
    created_at: timestamp
  }, %AnticipationCandidate{topic: topic, expire_at: expire_at}) do
    if points != 0 do
      points = abs(points)

      point_type = case p_type do
        "stream" -> "streaming points"
        "general" -> "general points"
      end

      verb = "points:changed:#{reason}"
      remove_previous_notifications(user_id, verb)

      description = case reason do
        "anticipation" -> "You just got a bonus of #{points / 10} #{point_type} that you can use to discuss \"#{topic}\". If you go live before #{Timex.format!(expire_at, "%H:%M", :strftime)} in UTC timezone, your points count will double and you can become a Legend faster"
        _ -> nil
      end

      if not is_nil(description) do
        Repo.insert(%Notification{
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: verb,
          actor_id: to_string(user_id),
          actor_type: @type_user,
          target_id: to_string(user_id),
          target_type: @type_user,
          timestamp: timestamp || DateTime.utc_now()
        })
      end
    end
  end

  def create_for(%Audit{
    user_id: user_id,
    points: points,
    reason: reason,
    p_type: p_type,
    created_at: timestamp
  }, %User{username: target_username}) do
    if points != 0 do
      points = abs(points)

      point_type = case p_type do
        "stream" -> "streaming points"
        "general" -> "general points"
      end

      verb = "points:changed:#{reason}"
      remove_previous_notifications(user_id, verb)

      description = case reason do
        "donate" -> "You just used #{points / 10} #{point_type} to donate to #{target_username}"
        "request" -> "You just received #{points / 10} #{point_type} from #{target_username}"
        "recover" -> "#{target_username} has used the points that you gave them just in time, thanks for your collaboration. You just earned #{points / 10} #{point_type}"
        "sender_bonus" -> "#{target_username} has used the points that you gave them just in time, thanks for your collaboration. You just earned #{points / 10} #{point_type}"
        "receiver_bonus" -> "You have fully used the donation from #{target_username} in time. You just earned #{points / 10} #{point_type}"
        _ -> nil
      end

      if not is_nil(description) do
        Repo.insert(%Notification{
          level: "info",
          recipient_id: user_id,
          public: false,
          description: description,
          verb: verb,
          actor_id: to_string(user_id),
          actor_type: @type_user,
          target_id: to_string(user_id),
          target_type: @type_user,
          timestamp: timestamp || DateTime.utc_now()
        })
      end
    end
  end

  defp remove_previous_post_reactions(recipient_id, actor_id, post_id) do
    Notification
    |> where(recipient_id: ^recipient_id)
    |> where([n], n.verb in ["posts:like", "posts:reacted"])
    |> where(actor_id: ^actor_id)
    |> where(target_id: ^post_id)
    |> Repo.delete_all()
  end

  defp remove_previous_post_comment_reactions(recipient_id, actor_id, comment_id) do
    Notification
    |> where(recipient_id: ^recipient_id)
    |> where([n], n.verb in ["post:comments:like", "post:comments:reacted"])
    |> where(actor_id: ^actor_id)
    |> where(action_id: ^comment_id)
    |> Repo.delete_all()
  end

  defp remove_previous_notifications(recipient_id, verb) do
    Notification
    |> where(recipient_id: ^recipient_id)
    |> where(verb: ^verb)
    |> Repo.delete_all()
  end

  def index(user_id, params) do
    n_filter = Map.get(params, "filter", "all")
    last_read = Map.get(params, "last_read", 0)

    query =
      Notification
      |> where(recipient_id: ^user_id)
      |> where([n], n.id >= ^last_read)
      |> order_by(desc: :id)
      |> preload(:recipient)

    if n_filter == "unread" do
      query
      |> where([n], n.unread == true)
      |> Repo.paginate(params)
    else
      query
      |> Repo.paginate(params)
    end
  end

  def user_notification_exists?(user_id, verb, created_after \\ nil) do
    query = from(n in Notification,
      where: n.verb == ^verb and n.recipient_id == ^user_id
    )

    query = if created_after do
      where(query, [n], n.timestamp >= ^created_after)
    else
      query
    end

    Repo.exists?(query)
  end

  def unread_count(user_id) when is_integer(user_id) do
    Notification
    |> where(recipient_id: ^user_id)
    |> where(unread: true)
    |> select([n], count(n.id))
    |> Repo.one()
  end

  def unread_counts(user_ids) when is_list(user_ids) do
    Notification
    |> where([n], n.recipient_id in ^user_ids)
    |> where(unread: true)
    |> group_by([n], n.recipient_id)
    |> select([n], {n.recipient_id, count(n.id)})
    |> Repo.all()
    |> Map.new()
  end

  def zip_users_with_unread_counts(users) do
    unread_counts = users |> Enum.map(& &1.id) |> Enum.uniq() |> unread_counts()
    Enum.map(users, fn user -> {user, unread_counts[user.id] || 0} end)
  end

  def mark_as_read(user_id, id) when is_integer(id) do
    mark_as_read(user_id, [id])
  end

  def mark_as_read(user_id, :all) do
    query = where(Notification, [n], n.recipient_id == ^user_id)

    Repo.update_all(query, set: [unread: false])
  end

  def mark_as_read(user_id, [notification_id]) do
    query =
      Notification
      |> where([n], n.recipient_id == ^user_id)
      |> where([n], n.id == ^notification_id)

    Repo.update_all(query, set: [unread: false])
  end

  defp utc_now do
    DateTime.utc_now()
  end
end
