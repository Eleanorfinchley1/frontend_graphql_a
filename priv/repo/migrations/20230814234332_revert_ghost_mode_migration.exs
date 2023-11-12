defmodule Repo.Migrations.RevertGhostModeMigration do
  use Ecto.Migration

  def change do
    alter table(:dropchat_streams) do
      remove :allow_ghosts
    end

    alter table(:chat_room_users) do
      remove :is_ghost
    end
  end
end
