defmodule Repo.Migrations.CreatePostCommentsTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_post_comments_changes() RETURNS trigger AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          PERFORM pg_notify(
            'post_comments_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'comment', row_to_json(NEW)
            )::text
          );

          RETURN NEW;
        ELSIF TG_OP = 'DELETE' THEN
          RETURN OLD;
        END IF;
      END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER notify_post_comments_changes_trg
      AFTER INSERT ON comments_comments FOR EACH ROW
      EXECUTE PROCEDURE notify_post_comments_changes();
    """)
  end

  def down do
    execute("DROP TRIGGER notify_post_comments_changes_trg;")
    execute("DROP FUNCTION notify_post_comments_changes();")
  end
end
