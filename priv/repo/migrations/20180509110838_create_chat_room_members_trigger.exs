defmodule Repo.Migrations.CreateChatRoomMembersTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_chat_room_users_changes() RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
      BEGIN
        IF TG_OP = 'INSERT' THEN
          current_row := NEW;
        ELSIF TG_OP = 'DELETE' THEN
          current_row := OLD;
        END IF;

        IF TG_OP = 'INSERT' OR TG_OP = 'DELETE' THEN
          PERFORM pg_notify(
            'chat_room_users_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'membership', row_to_json(current_row)
            )::text
          );
        END IF;

        RETURN current_row;
      END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER notify_chat_room_users_changes_trg
      AFTER INSERT ON chat_room_users FOR EACH ROW
      EXECUTE PROCEDURE notify_chat_room_users_changes();
    """)
  end

  def down do
    execute("DROP TRIGGER notify_chat_room_users_changes_trg;")
    execute("DROP FUNCTION notify_chat_room_users_changes();")
  end
end
