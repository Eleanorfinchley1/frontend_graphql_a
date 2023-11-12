defmodule Repo.Migrations.DropPlacesPlace do
  use Ecto.Migration

  def up do
    drop_if_exists index(:places_place, [:id])
    drop_if_exists table(:places_place_types)
    drop_if_exists table(:places_place)
  end

  def down do
  end
end
