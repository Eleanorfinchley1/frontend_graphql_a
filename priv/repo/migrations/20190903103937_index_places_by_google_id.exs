defmodule Repo.Migrations.IndexPlacesByGoogleId do
  use Ecto.Migration

  def up do
    drop_if_exists index(:places_place, [:id])
    drop_if_exists index(:places, [:place_id])
    execute "DROP INDEX IF EXISTS places_place_id_index;"
    Repo.delete_all("places")
    create unique_index(:places, [:place_id])
  end

  def down do
    drop index(:places, [:place_id])
  end
end
