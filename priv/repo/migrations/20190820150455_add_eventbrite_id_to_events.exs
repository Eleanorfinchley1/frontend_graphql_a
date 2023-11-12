defmodule Repo.Migrations.AddEventbriteIdToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :eventbrite_id, :bigint
    end

    create unique_index(:events, [:eventbrite_id])
  end
end
