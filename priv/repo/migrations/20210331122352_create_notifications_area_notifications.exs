defmodule Repo.Migrations.CreateNotificationsAreaNotifications do
  use Ecto.Migration

  def change do
    create(table(:notifications_area_notifications)) do
      add :notification_id, references(:notifications_notification)
      add :area_notification_id, references(:area_notifications)
      add :timetable_run_id, references(:area_notifications_timetable_runs)
      add :inserted_at, :timestamptz
    end

    create(index(:notifications_notification, [:verb]))
    create(index(:notifications_notification, [:timestamp]))
  end
end
