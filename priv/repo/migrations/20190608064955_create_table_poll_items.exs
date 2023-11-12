defmodule Repo.Migrations.CreateTablePollItems do
  use Ecto.Migration

  def change do
    create_if_not_exists table("poll_items") do
      add :title, :string, null: false, size: 512
      add :media_file_keys, {:array, :string}, default: []

      add :poll_id, references("poll")
    end
  end
end
