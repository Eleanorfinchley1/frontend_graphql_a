defmodule Repo.Migrations.AddEventProviderColumns do
  use Ecto.Migration

  def up do
    alter table(:accounts_userprofile) do
      add :event_provider, :event_provider
      add :provider_id, :string
    end

    alter table(:posts) do
      add :event_provider, :event_provider
      add :provider_id, :string
      add :provider_urls, {:array, :string}
    end

    alter table(:events) do
      add :event_provider, :event_provider
      add :provider_id, :string
      add :provider_urls, {:array, :string}
    end

    create unique_index(:accounts_userprofile, [:event_provider, :provider_id])
    create unique_index(:posts, [:event_provider, :provider_id])
    create unique_index(:events, [:event_provider, :provider_id])
  end
end
