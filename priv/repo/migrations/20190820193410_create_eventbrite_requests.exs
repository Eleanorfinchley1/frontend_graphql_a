defmodule Repo.Migrations.CreateEventbriteRequests do
  use Ecto.Migration

  def change do
    create table(:eventbrite_requests, primary_key: false) do
      add :datetime, :utc_datetime_usec, primary_key: true
      add :location, :geometry, null: false
      add :radius, :integer
    end

    create index(:eventbrite_requests, [:location], using: "GIST")
  end
end
