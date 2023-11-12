defmodule Repo.Migrations.CreateDropchatStreamsReactions do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE user_reaction_type_enum AS ENUM ('like', 'dislike')")

    create table(:dropchat_streams_reactions) do
      add :type, :user_reaction_type_enum, null: false
      add :stream_id, references(:dropchat_streams, on_delete: :delete_all, on_update: :update_all), null: false
      add :user_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), null: false
      timestamps(updated_at: false)
    end

    create(unique_index(:dropchat_streams_reactions, [:stream_id, :type, :user_id]))

    alter table(:dropchat_streams) do
      add :reactions_count, :jsonb
    end
  end
end
