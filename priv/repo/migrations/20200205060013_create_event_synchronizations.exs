defmodule Repo.Migrations.CreateEventSynchronizations do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE event_synchronization_status AS ENUM ('pending', 'failed', 'completed')")

    create table(:event_synchronizations) do
      add :event_provider, :event_provider, null: false
      add :started_at, :utc_datetime_usec
      add :location, :geometry, null: false
      add :radius, :float
      add :status, :event_synchronization_status, null: false, default: "pending"
    end

    create index(:event_synchronizations, [:event_provider, :started_at])
    create index(:event_synchronizations, [:location], using: "GIST")
  end

  def down do
    drop table(:event_synchronizations)
    execute("DROP TYPE event_synchronization_status")
  end
end
