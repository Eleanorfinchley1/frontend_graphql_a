defmodule Repo.Migrations.CreateLivestreamViews do
  use Ecto.Migration

  def change do
    create table(:livestream_views) do
      add(:user_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:livestream_id, references(:livestreams, on_delete: :delete_all), null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create(unique_index(:livestream_views, [:user_id, :livestream_id]))
  end
end
