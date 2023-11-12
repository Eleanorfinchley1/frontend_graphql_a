defmodule Repo.Migrations.AddRoleToChatRoomUsers do
  use Ecto.Migration

  def up do
    alter table(:chat_room_users) do
      add :role, :string
    end

    execute("SET CONSTRAINTS ALL IMMEDIATE;")

    execute("""
      UPDATE chat_room_users cru SET role = CASE WHEN r.chat_type = 'dropchat' THEN 'guest' ELSE 'member' END
      FROM chat_room r WHERE r.id = cru.room_id;
    """)

    execute("""
      INSERT INTO chat_room_users (room_id, userprofile_id, role)
      SELECT room_id, userprofile_id, 'administrator' FROM chat_room_administrators
      ON CONFLICT (room_id, userprofile_id) DO UPDATE SET role = EXCLUDED.role;
    """)

    execute("""
      INSERT INTO chat_room_users (room_id, userprofile_id, role)
      SELECT dropchat_id, user_id, 'member' FROM dropchat_elevated_privileges
      ON CONFLICT (room_id, userprofile_id) DO UPDATE SET role = EXCLUDED.role;
    """)

    alter table(:chat_room_users) do
      modify :role, :string, null: false
    end
  end

  def down do
    alter table(:chat_room_users) do
      remove(:role)
    end
  end
end
