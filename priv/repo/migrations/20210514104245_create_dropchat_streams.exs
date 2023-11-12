defmodule Repo.Migrations.CreateDropchatStreams do
  use Ecto.Migration

  def change do
    create table(:dropchat_streams) do
      add :key, :string, null: false
      add :dropchat_id, references(:chat_room, on_delete: :delete_all, on_update: :update_all), null: false
      add :admin_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), null: false
      add :title, :string
      add :status, :string, null: false
      timestamps(updated_at: false)
    end

    create(unique_index(:dropchat_streams, [:dropchat_id, :key]))
    create(index(:dropchat_streams, [:dropchat_id, :status]))
  end
end
