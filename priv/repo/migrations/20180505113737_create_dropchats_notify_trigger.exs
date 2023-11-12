defmodule Repo.Migrations.CreateDropchatsNotifyTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_dropchats_changes() RETURNS trigger AS $$
      BEGIN
        IF TG_OP = 'INSERT' THEN
          IF (NEW.private OR NEW.location = NULL) THEN
            RETURN NEW;
          END IF;

          PERFORM pg_notify(
            'dropchats_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'dropchat', row_to_json(NEW)
            )::text
          );
        END IF;

        RETURN NEW;
      END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER notify_dropchats_changes_trg
      AFTER INSERT ON chat_room FOR EACH ROW
      EXECUTE PROCEDURE notify_dropchats_changes();
    """)
  end

  def down do
    execute("DROP TRIGGER notify_dropchats_changes_trg;")
    execute("DROP FUNCTION notify_dropchats_changes();")
  end
end
