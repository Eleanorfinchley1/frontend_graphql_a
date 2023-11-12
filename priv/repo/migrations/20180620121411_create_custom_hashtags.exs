defmodule Repo.Migrations.CreateCustomHashtags do
  use Ecto.Migration

  def change do
    create table(:custom_hashtags) do
      add(:value, :string)
      timestamps()
    end

    create(unique_index(:custom_hashtags, [:value]))

    create table(:chat_message_custom_hashtags) do
      add(:message_id, references(:chat_message, on_delete: :delete_all))
      add(:hashtag_id, references(:custom_hashtags, on_delete: :delete_all))

      timestamps(updated_at: false)
    end

    create(index(:chat_message_custom_hashtags, [:message_id]))
    create(index(:chat_message_custom_hashtags, [:hashtag_id]))
  end
end
