defmodule BillBored.Clickhouse.PostView do
  alias BillBored.Post
  alias BillBored.User

  defstruct [
    :post_id, :business_id, :geohash, :lon, :lat,
    :user_id, :age, :sex, :country, :city, :viewed_at
  ]

  def build(%Post{id: post_id, business_id: business_id}, %User{} = user, attrs) do
    with {:ok, geohash, lon, lat} <- prepare_geo(attrs) do
      {:ok,
        %__MODULE__{
          post_id: post_id,
          business_id: business_id,
          geohash: geohash,
          lon: lon,
          lat: lat,
          user_id: user.id,
          age: user_age(user),
          sex: user.sex || "-",
          country: attrs["country"],
          city: attrs["city"],
          viewed_at: attrs["viewed_at"] || DateTime.utc_now()
      }}
    end
  end

  defp prepare_geo(%{"lon" => lon, "lat" => lat}) do
    lon = String.to_float(lon)
    lat = String.to_float(lat)
    geohash = Geohash.encode(lat, lon, 12)
    {:ok, geohash, lon, lat}
  end

  defp prepare_geo(_), do: {:error, :missing_location}

  defp user_age(%User{birthdate: nil}), do: nil

  defp user_age(%User{birthdate: birthdate}) do
    Timex.diff(DateTime.utc_now(), birthdate, :years)
  end
end
