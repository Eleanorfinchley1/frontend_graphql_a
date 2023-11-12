defmodule BillBored.Workers.NotifyLocationRewards do
  import Ecto.Query

  require Logger


  alias BillBored.LocationReward
  alias BillBored.LocationRewards.Notification, as: LocationRewardRecipients
  alias BillBored.Notifications.NotificationsLocationRewards

  def call(now \\ DateTime.utc_now()) do
    user_location_rewards = LocationRewardRecipients
    |> join(:left, [lr], lrn in NotificationsLocationRewards, on: lr.id == lrn.location_reward_notification_id)
    |> where([lr, lrn], is_nil(lrn.id))
    |> join(:inner, [lr, _lrn], l in LocationReward, on: l.id == lr.location_reward_id)
    |> where([lr, lrn, l], l.ended_at > ^now)
    |> limit(1_000)
    |> preload([
      user: [devices: :devices],
    ])
    |> select([lr, lrn, l], %{
      lr |
      location_reward: l
    })
    |> Repo.all()

    Enum.each(user_location_rewards, fn args ->
      notification = Notifications.process_location_reward_notification(args)
      %NotificationsLocationRewards{
        notification_id: notification.id,
        location_reward_notification_id: args.id,
        inserted_at: DateTime.utc_now()
      }
      |> Repo.insert()
    end)
    Logger.info("Send location reward notifiction to #{length(user_location_rewards)} users")
  end
end
