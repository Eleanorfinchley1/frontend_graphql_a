defmodule Repo.Migrations.AddLocationGeohashToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :location_geohash, :bigint
    end

    create(index(:posts, [:location_geohash]))
  end
end
