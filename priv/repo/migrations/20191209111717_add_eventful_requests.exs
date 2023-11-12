defmodule Repo.Migrations.AddEventfulRequests do
  use Ecto.Migration

  def change do
    create table(:eventful_requests, primary_key: false) do
      add :datetime, :utc_datetime_usec, primary_key: true
      add :location, :geometry, null: false
      add :radius, :integer
    end

    create index(:eventful_requests, [:location], using: "GIST")
  end
end
