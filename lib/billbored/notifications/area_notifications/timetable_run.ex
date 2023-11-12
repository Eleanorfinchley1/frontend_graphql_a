defmodule BillBored.Notifications.AreaNotifications.TimetableRun do
  @moduledoc false

  use BillBored, :schema
  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotifications.TimetableEntry

  schema "area_notifications_timetable_runs" do
    field :timestamp, :integer
    field :notifications_count, :integer

    belongs_to :timetable_entry, TimetableEntry
    belongs_to :area_notification, AreaNotification

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end
end
