defmodule Repo.Migrations.CreateUniversityTable do
  use Ecto.Migration

  def up do
    create table("university") do
      add :name, :string
      add :country, :string
      add :allowed, :boolean
    end

    create unique_index(:university, [:name, :country])

  end

  def down do
    drop table("university")
  end
end
