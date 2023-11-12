defmodule Repo.Migrations.CreateAreaNotificationsTimetableRuns do
  use Ecto.Migration

  def change do
    create(table(:area_notifications_timetable_runs)) do
      add :timetable_entry_id, references(:area_notifications_timetable_entries)
      add :area_notification_id, references(:area_notifications)
      add :timestamp, :integer
      add :notifications_count, :integer
      add :inserted_at, :timestamptz
      add :updated_at, :timestamptz
    end

    create(
      index(
        :area_notifications_timetable_runs,
        [:timetable_entry_id, :area_notification_id, :timestamp],
        unique: true,
        name: :area_notifications_timetable_runs_timestamp_unique
      )
    )
  end
end
