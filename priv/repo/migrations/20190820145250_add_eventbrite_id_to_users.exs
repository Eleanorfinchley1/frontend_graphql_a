defmodule Repo.Migrations.AddEventbriteIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:accounts_userprofile) do
      add :eventbrite_id, :bigint
    end

    create unique_index(:accounts_userprofile, [:eventbrite_id])
  end
end
