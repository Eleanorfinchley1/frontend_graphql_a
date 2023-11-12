defmodule Repo.Migrations.AddMutedChats do
  use Ecto.Migration

  def change do
    alter table(:chat_room_users) do
      add :muted?, :boolean, default: false
    end
  end
end
