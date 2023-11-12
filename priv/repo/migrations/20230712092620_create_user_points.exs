defmodule Repo.Migrations.CreateUserPoints do
  use Ecto.Migration

  def change do
    create table(:user_points, primary_key: false) do
      add :user_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), primary_key: true
      add :stream_points, :bigint, null: false
      add :general_points, :bigint, null: false
    end

    create(index(:user_points, [:user_id]))
  end
end
