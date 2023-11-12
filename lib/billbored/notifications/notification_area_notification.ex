defmodule BillBored.Notifications.NotificationAreaNotification do
  @moduledoc false

  use BillBored, :schema

  alias BillBored.Notification
  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotifications.TimetableRun


  schema "notifications_area_notifications" do
    belongs_to :notification, Notification
    belongs_to :area_notification, AreaNotification
    belongs_to :timetable_run, TimetableRun

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end
end
