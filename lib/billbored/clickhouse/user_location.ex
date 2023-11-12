defmodule BillBored.Clickhouse.UserLocation do
  alias BillBored.User
  alias BillBored.Geo.Point

  defstruct [
    :user_id, :geohash, :visited_at
  ]

  def build(%User{id: user_id}, %Point{long: lon, lat: lat}, attrs \\ %{}) do
    with geohash <- Geohash.encode(lat, lon, 12) do
      {:ok,
        %__MODULE__{
          user_id: user_id,
          geohash: geohash,
          visited_at: attrs["visited_at"] || attrs[:visited_at] || DateTime.utc_now()
      }}
    end
  end
end
