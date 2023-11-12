defmodule Repo.Migrations.CreateDropchatElevatedPrivilegesTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_dropchat_elevated_privileges_changes() RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
      BEGIN
        IF TG_OP = 'INSERT' THEN
          current_row := NEW;
        ELSIF TG_OP = 'DELETE' THEN
          current_row := OLD;
        END IF;

        IF TG_OP = 'INSERT' THEN
          PERFORM pg_notify(
            'dropchat_elevated_privileges_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'elevated_privilege', row_to_json(current_row)
            )::text
          );
        END IF;

        RETURN current_row;
      END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER notify_dropchat_elevated_privileges_changes_trg
      AFTER INSERT ON dropchat_elevated_privileges FOR EACH ROW
      EXECUTE PROCEDURE notify_dropchat_elevated_privileges_changes();
    """)
  end

  def down do
    execute("DROP TRIGGER notify_dropchat_elevated_privileges_changes_trg;")
    execute("DROP FUNCTION notify_dropchat_elevated_privileges_changes();")
  end
end
