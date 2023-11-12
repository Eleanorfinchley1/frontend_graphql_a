defmodule Repo.Migrations.CreateChangePassword do
  use Ecto.Migration

  def change do
    create table(:change_password) do
      add(:hash, :text, null: false)
      add(:user_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create(index(:change_password, [:user_id]))
  end
end
