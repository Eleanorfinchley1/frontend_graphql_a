defmodule Repo.Migrations.CreateDropchatStreamsSpeakers do
  use Ecto.Migration

  def change do
    create table(:dropchat_streams_speakers) do
      add :stream_id, references(:dropchat_streams, on_delete: :delete_all, on_update: :update_all), null: false
      add :user_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), null: false
      timestamps(updated_at: false)
    end

    create(unique_index(:dropchat_streams_speakers, [:stream_id, :user_id]))
  end
end
