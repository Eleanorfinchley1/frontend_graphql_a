defmodule Repo.Migrations.CleanPlacesTypesJoinTable do
  use Ecto.Migration

  def up do
    Repo.delete_all("places_typeship")
  end

  def down do
  end
end
