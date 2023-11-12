defmodule Web.NotificationView do
  use Web, :view

  def render("index.json", %{conn: conn, data: notifications}) do
    Web.ViewHelpers.index(conn, notifications, __MODULE__)
  end

  def render("show.json", %{notification: notification}) do
    render_notification(notification.verb, notification)
  end

  defp render_notification("posts:new:popular" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("dropchats:new:popular" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      dropchat_key: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("posts:like" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      upvoter_id: notification.actor_id,
      upvote_id: notification.action_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("posts:reacted" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      downvoter_id: notification.actor_id,
      downvote_id: notification.action_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("post:comments:like" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      upvoter_id: notification.actor_id,
      post_id: notification.target_id,
      comment_id: notification.action_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("post:comments:reacted" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      downvoter_id: notification.actor_id,
      comment_id: notification.action_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("posts:comment" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      author_id: notification.actor_id,
      comment_id: notification.action_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("posts:approve:request" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      requester_id: notification.actor_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("posts:approve:request:reject" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      rejector_id: notification.actor_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("chats:privilege:granted" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      dropchat_key: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("chats:privilege:request" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      requester_id: notification.actor_id,
      request_id: notification.action_id,
      dropchat_key: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("chats:message:tagged" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      room_key: notification.target_id,
      tagger_id: notification.actor_id,
      message_id: notification.action_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("chats:message:reply" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      room_key: notification.target_id,
      sender_id: notification.actor_id,
      reply_id: notification.action_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("events:matching_interests" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      event_id: notification.action_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("following:new" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      follower_username: notification.actor_id,
      follower_id: notification.target_id,
      following_id: notification.action_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("poll_vote:new" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      voter_id: notification.actor_id,
      poll_id: notification.action_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("event:attendant:new" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      attendant_id: notification.actor_id,
      event_id: notification.action_id,
      post_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("event:approaching" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      post_id: notification.target_id,
      event_id: notification.action_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("area_notifications:scheduled" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("dropchats:new:followed" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      dropchat_key: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("access:granted" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("dropchats:streams:new:followed" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      dropchat_key: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification(<<"points:changed:", _::binary>> = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      user_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification("location_reward:notify" = verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      user_id: notification.target_id,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end

  defp render_notification(verb, notification) do
    %{
      id: notification.id,
      level: notification.level,
      description: notification.description,
      verb: verb,
      timestamp: notification.timestamp,
      unread: notification.unread
    }
  end
end
