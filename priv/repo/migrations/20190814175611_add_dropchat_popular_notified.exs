defmodule Repo.Migrations.AddDropchatPopularNotified do
  use Ecto.Migration

  def change do
    alter table(:chat_room) do
      add :popular_notified?, :boolean, default: false
    end
  end
end
