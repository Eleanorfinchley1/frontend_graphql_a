defmodule Repo.Migrations.CreateTopicsTable do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :meta, {:array, :jsonb}, null: false
    end
  end
end
