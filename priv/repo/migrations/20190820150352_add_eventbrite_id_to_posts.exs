defmodule Repo.Migrations.AddEventbriteIdToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :eventbrite_id, :bigint
    end

    create unique_index(:posts, [:eventbrite_id])
  end
end
