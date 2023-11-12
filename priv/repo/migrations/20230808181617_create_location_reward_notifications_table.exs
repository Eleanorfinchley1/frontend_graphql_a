defmodule Repo.Migrations.CreateLocationRewardNotificationsTable do
  use Ecto.Migration

  def change do
    create(table(:location_reward_notifications)) do
      add :user_id, references(:accounts_userprofile, on_delete: :delete_all)
      add :location_reward_id, references(:location_rewards, on_delete: :delete_all)
      timestamps(updated_at: false)
    end

    create(index(:location_reward_notifications, [:user_id, :location_reward_id], unique: true))
  end
end
