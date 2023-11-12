defmodule Repo.Migrations.AddEventfulIds do
  use Ecto.Migration

  def change do
    alter table(:accounts_userprofile) do
      add :eventful_id, :string
    end

    create unique_index(:accounts_userprofile, [:eventful_id])

    alter table(:posts) do
      add :eventful_id, :string
    end

    create unique_index(:posts, [:eventful_id])

    alter table(:events) do
      add :eventful_id, :string
    end

    create unique_index(:events, [:eventful_id])
  end
end
