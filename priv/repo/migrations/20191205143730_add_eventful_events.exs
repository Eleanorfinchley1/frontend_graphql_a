defmodule Repo.Migrations.AddEventfulEvents do
  use Ecto.Migration

  def change do
    create table(:eventful_events, primary_key: false) do
      add :id, :string, primary_key: true
      add :data, :jsonb, null: false
      timestamps()
    end
  end
end
