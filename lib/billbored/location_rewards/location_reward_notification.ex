defmodule BillBored.LocationRewards.Notification do
  @moduledoc false

  use BillBored, :schema

  schema "location_reward_notifications" do
    belongs_to :user, BillBored.User
    belongs_to :location_reward, BillBored.LocationReward

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(area_notification_reception, attrs \\ %{}) do
    area_notification_reception
    |> cast(attrs, [:user_id, :location_reward_id])
    |> cast_assoc(:user)
    |> cast_assoc(:location_reward)
  end
end
