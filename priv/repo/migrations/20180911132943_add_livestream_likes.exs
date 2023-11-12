defmodule Repo.Migrations.AddLivestreamLikes do
  use Ecto.Migration

  def up do
    create table(:livestream_upvotes) do
      add(:user_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:livestream_id, references(:livestreams, on_delete: :delete_all), null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create table(:livestream_downvotes) do
      add(:user_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:livestream_id, references(:livestreams, on_delete: :delete_all), null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end
  end

  def down do
    drop(table(:livestream_upvotes))
    drop(table(:livestream_downvotes))
  end
end
