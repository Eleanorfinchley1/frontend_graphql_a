defmodule Repo.Migrations.CreateKVEntries do
  use Ecto.Migration

  def up do
    create(table(:kv_entries, primary_key: false)) do
      add :key, :string, primary_key: true
      add :value, :jsonb

      timestamps(inserted_at: false, updated_at: :updated_at)
    end

    execute("INSERT INTO kv_entries (key, value, updated_at) VALUES ('covid_info', '{}'::jsonb, NOW())")
  end

  def down do
    drop(table(:kv_entries))
  end
end
