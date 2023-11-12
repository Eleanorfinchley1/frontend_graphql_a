defmodule Repo.Migrations.CreateTablePlaces do
  use Ecto.Migration

  def change do
    create table("places") do
      add :name, :string, null: false, size: 512
      add :place_id, :string, null: false, size: 512
      add :address, :string, null: false, size: 512
      add :icon, :string, size: 2048
      add :vicinity, :string, size: 512, default: ""
      add :location, :geometry, null: false

      timestamps()
    end
  end
end
