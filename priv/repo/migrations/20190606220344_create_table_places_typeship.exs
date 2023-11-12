defmodule Repo.Migrations.CreateTablePlacesTypeship do
  use Ecto.Migration

  def change do
    create table("places_typeship") do
      add :place_id, references("places", on_delete: :delete_all)
      add :type_id, references("places_types", on_delete: :delete_all)
    end
  end
end
