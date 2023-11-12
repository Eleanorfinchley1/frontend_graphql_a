defmodule Repo.Migrations.CreateDropchatStreamSpeakersReactions do
  use Ecto.Migration

  def change do
    create table(:dropchat_stream_speakers_reactions) do
      add :stream_id, references(:dropchat_streams, on_delete: :delete_all, on_update: :update_all), null: false
      add :speaker_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), null: false
      add :user_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), null: false
      add :type, :user_reaction_type_enum, null: false

      timestamps(updated_at: false)
    end
  end
end
