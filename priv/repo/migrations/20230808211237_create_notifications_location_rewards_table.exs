defmodule Repo.Migrations.CreateNotificationsLocationRewardsTable do
  use Ecto.Migration

  def change do
    create(table(:notifications_location_rewards)) do
      add :notification_id, references(:notifications_notification, on_delete: :delete_all)
      add :location_reward_notification_id, references(:location_reward_notifications, on_delete: :delete_all)
      timestamps(updated_at: false)
    end

    create(index(:notifications_location_rewards, [:notification_id, :location_reward_notification_id], unique: true))
  end
end
