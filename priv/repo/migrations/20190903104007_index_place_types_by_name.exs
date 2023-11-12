defmodule Repo.Migrations.IndexPlaceTypesByName do
  use Ecto.Migration

  def change do
    Repo.delete_all("places_types")
    drop_if_exists index(:places_types, [:name])
    create unique_index(:places_types, [:name])
  end
end
