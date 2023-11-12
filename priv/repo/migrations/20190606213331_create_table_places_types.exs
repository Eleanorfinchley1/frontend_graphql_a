defmodule Repo.Migrations.CreateTablePlacesTypes do
  use Ecto.Migration

  def change do
    create table("places_types") do
      add :name, :text, null: false
    end
  end
end
