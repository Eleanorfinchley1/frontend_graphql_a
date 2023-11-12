defmodule Repo.Migrations.CreateAreaNotificationsTimetableEntries do
  use Ecto.Migration

  def change do
    create(table(:area_notifications_timetable_entries)) do
      add :time, :time
      add :categories, {:array, :string}
      add :any_category, :boolean, default: false
      add :template, :string
      add :inserted_at, :timestamptz
      add :updated_at, :timestamptz
    end
  end
end
