defmodule Repo.Migrations.DropUpvotesDownvotesCreateVotes do
  use Ecto.Migration

  def change do
    drop(table(:livestream_upvotes))
    drop(table(:livestream_downvotes))

    create table(:livestream_votes) do
      add(:user_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:livestream_id, references(:livestreams, on_delete: :delete_all), null: false)
      add(:vote_type, :string)

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create(unique_index(:livestream_votes, [:user_id, :livestream_id]))
  end
end
