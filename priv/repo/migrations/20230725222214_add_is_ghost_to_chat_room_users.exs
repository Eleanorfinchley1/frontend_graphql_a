defmodule Repo.Migrations.AddIsGhostToChatRoomUsers do
  use Ecto.Migration

  def change do
    alter table(:chat_room_users) do
      add :is_ghost, :boolean, default: false
    end
  end
end
