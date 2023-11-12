defmodule BillBored.Notification do
  @moduledoc "schema for notifications_notification table"

  use BillBored, :schema
  alias BillBored.User

  alias BillBored.Notifications.NotificationAreaNotification

  @type t :: %__MODULE__{}

  schema "notifications_notification" do
    belongs_to(:recipient, User)

    # "success", "info", "warning", "error"
    field(:level, :string, default: "info")
    field(:unread, :boolean, default: true)
    field(:deleted, :boolean, default: false)
    field(:emailed, :boolean, default: false)
    field(:public, :boolean)
    field(:description, :string)

    # user
    field(:actor_id, :string, default: "", source: :actor_object_id)
    # 9
    field(:actor_type, :integer, default: -1, source: :actor_content_type_id)

    field(:action_id, :string, default: "", source: :action_object_object_id)
    # chats:privilege:request, chats:privilege:granted, posts:comment, posts:like
    field(:verb, :string)

    # post, comment, chat, …
    field(:target_id, :string, default: "", source: :target_object_id)
    # 13, 20, 25
    field(:target_type, :integer, default: -1, source: :target_content_type_id)

    # TODO: use `created` instead
    field(:timestamp, :utc_datetime_usec)

    has_many :notification_area_notifications, NotificationAreaNotification

    has_many :area_notifications, through: [:notification_area_notifications, :area_notification]
    has_many :timetable_runs, through: [:notification_area_notifications, :timetable_run]
  end
end
