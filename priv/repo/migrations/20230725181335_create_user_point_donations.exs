defmodule Repo.Migrations.CreateUserPointDonations do
  use Ecto.Migration

  def change do
    create table(:user_point_donations) do
      add :request_id, references(:user_point_requests), null: false
      add :sender_id, references(:accounts_userprofile), null: false
      add :receiver_id, references(:accounts_userprofile), null: false
      add :stream_points, :bigint, null: false
      timestamps(updated_at: false)
    end
  end
end
