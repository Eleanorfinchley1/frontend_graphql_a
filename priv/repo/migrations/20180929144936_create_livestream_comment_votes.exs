defmodule Repo.Migrations.CreateLivestreamCommentVotes do
  use Ecto.Migration

  def change do
    create table(:livestream_comment_votes) do
      add(:user_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:comment_id, references(:livestream_comments, on_delete: :delete_all), null: false)
      add(:vote_type, :string)

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create(unique_index(:livestream_comment_votes, [:user_id, :comment_id]))
  end
end
