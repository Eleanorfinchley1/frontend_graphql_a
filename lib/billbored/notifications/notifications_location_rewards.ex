defmodule BillBored.Notifications.NotificationsLocationRewards do
  @moduledoc false

  use BillBored, :schema

  alias BillBored.Notification
  alias BillBored.LocationRewards.Notification, as: LocationRewardNotification


  schema "notifications_location_rewards" do
    belongs_to :notification, Notification
    belongs_to :location_reward_notification, LocationRewardNotification

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end
end
