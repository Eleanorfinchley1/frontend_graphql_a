defmodule Repo.Migrations.AddGhostAllowedIntoChatRoom do
  use Ecto.Migration

  def change do
    alter table(:chat_room) do
      add :ghost_allowed, :boolean, default: true
    end
  end
end
