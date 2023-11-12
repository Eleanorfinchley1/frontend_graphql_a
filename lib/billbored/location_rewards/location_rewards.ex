defmodule BillBored.LocationRewards do
  @moduledoc ""
  import Ecto.Query
  import Geo.PostGIS, only: [st_distance_in_meters: 2]

  alias BillBored.LocationReward
  alias BillBored.LocationRewards.Notification

  def create(params) do
    %LocationReward{}
    |> LocationReward.changeset(params)
    |> Repo.insert()
  end

  def notify_reward_to_user(reward_id, user_id) do
    %Notification{}
    |> Notification.changeset(%{
      "user_id" => user_id,
      "location_reward_id" => reward_id
    })
    |> Repo.insert()
  end

  def get_nearest_location_rewards(%BillBored.Geo.Point{} = point) do
    LocationReward
    |> where([lr], st_distance_in_meters(lr.location, ^point) <= lr.radius)
    |> where([lr], lr.started_at <= ^DateTime.utc_now())
    |> where([lr], lr.ended_at >= ^DateTime.utc_now())
    |> Repo.all()
  end

end
