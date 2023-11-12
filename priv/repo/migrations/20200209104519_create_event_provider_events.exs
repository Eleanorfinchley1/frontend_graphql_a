defmodule Repo.Migrations.CreateEventProviderEvents do
  use Ecto.Migration

  def change do
    create table(:event_provider_events, primary_key: false) do
      add :event_provider, :event_provider, primary_key: true
      add :provider_id, :string, primary_key: true
      add :event_synchronization_id, references(:event_synchronizations, on_delete: :nilify_all)
      add :data, :jsonb, null: false

      timestamps()
    end

    create index(:event_provider_events, [:event_synchronization_id], where: "event_synchronization_id IS NOT NULL")
  end
end
