defmodule Repo.Migrations.DropNotifyTriggers do
  use Ecto.Migration

  def change do
    execute("DROP TRIGGER notify_post_likes_changes_trg ON pst_post_upvotes;")
    execute("DROP FUNCTION notify_post_likes_changes();")
    execute("DROP TRIGGER notify_post_comments_changes_trg ON comments_comments;")
    execute("DROP FUNCTION notify_post_comments_changes();")
    execute("DROP TRIGGER notify_chat_room_pending_changes_trg ON chat_room_pending;")
    execute("DROP FUNCTION notify_chat_room_pending_changes();")

    execute(
      "DROP TRIGGER notify_dropchat_elevated_privileges_changes_trg ON dropchat_elevated_privileges;"
    )

    execute("DROP FUNCTION notify_dropchat_elevated_privileges_changes();")
    execute("DROP TRIGGER notify_chat_room_users_changes_trg ON chat_room_users;")
    execute("DROP FUNCTION notify_chat_room_users_changes();")
    execute("DROP TRIGGER notify_dropchats_changes_trg ON chat_room;")
    execute("DROP FUNCTION notify_dropchats_changes();")
    execute("DROP TRIGGER notify_posts_changes_trg ON pst_post;")
    execute("DROP FUNCTION notify_posts_changes();")
  end
end
