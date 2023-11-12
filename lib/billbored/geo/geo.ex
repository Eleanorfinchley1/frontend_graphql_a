defmodule BillBored.Geo do
  import BillBored.ServiceRegistry, only: [service: 1]
  alias BillBored.Place.GoogleApi.Places, as: PlacesAPI

  # in km
  @earth_radius 6378.137
  @min_distance 800
  @max_distance 1000
  @miles_in_meter 0.000621371

  # TODO
  def fake_place(nil), do: nil
  def fake_place([lat, long]), do: fake_place({lat, long})

  def fake_place({lat, long}) do
    case service(PlacesAPI).search(%{lat: lat, long: long}, @max_distance,
           ignored_types: ["locality", "political"],
           min_distance: @min_distance
         ) do
      {:ok, places} -> {:ok, Enum.random(places)}
      :error -> :error
    end
  end

  @spec within?(%BillBored.Geo.Point{}, %BillBored.Geo.Point{}, pos_integer | float) :: boolean
  def within?(post_location, user_location, radius)

  def within?(
        %BillBored.Geo.Point{lat: post_lat_deg, long: post_long_deg},
        %BillBored.Geo.Point{lat: user_lat_deg, long: user_long_deg},
        radius
      ) do
    post_lat_rad = deg_to_rad(post_lat_deg)
    post_long_rad = deg_to_rad(post_long_deg)

    user_lat_rad = deg_to_rad(user_lat_deg)
    user_long_rad = deg_to_rad(user_long_deg)

    distance(post_lat_rad, post_long_rad, user_lat_rad, user_long_rad) < radius
  end

  def distance(lat1, long1, lat2, long2) do
    # https://en.wikipedia.org/wiki/Haversine_formula

    diff_lat_rad = lat1 - lat2
    diff_long_rad = long1 - long2

    a = hav(diff_lat_rad) + hav(diff_long_rad) * :math.cos(lat2) * :math.cos(lat1)

    c = 2 * :math.atan2(:math.sqrt(a), :math.sqrt(1 - a))
    d = @earth_radius * c

    # in meters
    d * 1000
  end

  def meters_to_miles(meters), do: @miles_in_meter * meters

  defp deg_to_rad(deg) do
    deg * :math.pi() / 180
  end

  defp hav(theta) do
    :math.pow(:math.sin(theta / 2), 2)
  end
end
