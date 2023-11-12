defmodule Repo.Migrations.CreateLocationRewardsTable do
  use Ecto.Migration

  def change do
    create table(:location_rewards) do
      add :location, :geometry, null: false
      add :radius, :float, null: false
      add :stream_points, :bigint, null: false
      add :started_at, :timestamp, null: false
      add :ended_at, :timestamp, null: false
      timestamps()
    end
  end
end
