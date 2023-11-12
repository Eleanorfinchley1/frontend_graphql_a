defmodule Repo.Migrations.CreateUserPointRequests do
  use Ecto.Migration

  def change do
    create table(:user_point_requests) do
      add :user_id, references(:accounts_userprofile), null: false
      timestamps(updated_at: false)
    end
  end
end
