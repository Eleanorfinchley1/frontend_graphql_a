defmodule Repo.Migrations.AddPostPopularNotified do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :popular_notified?, :boolean, default: false
    end
  end
end
