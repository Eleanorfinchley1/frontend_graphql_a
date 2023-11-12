defmodule Repo.Migrations.AddSourceFieldForPlaces do
  use Ecto.Migration

  def change do
    alter table("places") do
      add :source, :string, size: 32, default: "google maps"
    end
  end
end
