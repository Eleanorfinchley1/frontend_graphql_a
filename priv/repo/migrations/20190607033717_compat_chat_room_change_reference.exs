defmodule Repo.Migrations.CompatChatRoomChangeReference do
  use Ecto.Migration

  def change do
    alter table(:chat_room) do
      modify :place_id, references(:places)
    end
  end
end
