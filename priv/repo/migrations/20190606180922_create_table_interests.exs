defmodule Repo.Migrations.CreateTableInterests do
  use Ecto.Migration

  def change do
    create_if_not_exists table("interests") do
      add :hashtag, :string, null: false
      add :disabled?, :boolean, default: false

      timestamps()
    end
  end
end
