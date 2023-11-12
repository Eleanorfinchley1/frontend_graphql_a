defmodule BillBored.Notifications.AreaNotificationReception do
  @moduledoc false

  use BillBored, :schema

  schema "area_notifications_receptions" do
    belongs_to :user, BillBored.User
    belongs_to :area_notification, BillBored.Notifications.AreaNotification

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(area_notification_reception, attrs \\ %{}) do
    area_notification_reception
    |> cast(attrs, [:user_id, :area_notification_id])
    |> cast_assoc(:user)
    |> cast_assoc(:area_notification)
    |> foreign_key_constraint(:user, name: :area_notifications_receptions_user_id_fkey)
    |> foreign_key_constraint(:area_notification, name: :area_notifications_receptions_area_notification_id_fkey)
    |> foreign_key_constraint(:area_notification, name: :area_notifications_receptions_user_id_area_notification_id_inde)
  end
end
