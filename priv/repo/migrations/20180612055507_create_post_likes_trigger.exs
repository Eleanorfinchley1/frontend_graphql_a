defmodule Repo.Migrations.CreatePostLikesTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_post_likes_changes() RETURNS trigger AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          PERFORM pg_notify(
            'post_likes_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'like', row_to_json(NEW)
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
    CREATE TRIGGER notify_post_likes_changes_trg
      AFTER INSERT ON pst_post_upvotes FOR EACH ROW
      EXECUTE PROCEDURE notify_post_likes_changes();
    """)
  end

  def down do
    execute("DROP TRIGGER notify_post_likes_changes_trg;")
    execute("DROP FUNCTION notify_post_likes_changes();")
  end
end
