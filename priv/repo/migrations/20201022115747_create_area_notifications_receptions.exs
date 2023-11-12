defmodule Repo.Migrations.CreateAreaNotificationsReceptions do
  use Ecto.Migration

  def change do
    create(table(:area_notifications_receptions)) do
      add :user_id, references(:accounts_userprofile)
      add :area_notification_id, references(:area_notifications)
      timestamps(updated_at: false)
    end

    create(index(:area_notifications_receptions, [:user_id, :area_notification_id], unique: true))
  end
end
