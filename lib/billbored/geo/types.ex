defmodule BillBored.Geo.Types do
  @moduledoc false
  @behaviour Postgrex.Extension

  @impl true
  def init(opts) do
    Geo.PostGIS.Extension.init(opts)
  end

  @impl true
  def matching(state) do
    Geo.PostGIS.Extension.matching(state)
  end

  @impl true
  def format(state) do
    Geo.PostGIS.Extension.format(state)
  end

  @impl true
  def encode(_opts) do
    quote location: :keep do
      %BillBored.Geo.Point{lat: lat, long: long} ->
        data = Geo.WKT.encode!(%Geo.Point{coordinates: {long, lat}, srid: 4326})
        [<<IO.iodata_length(data)::int32>> | data]

      %BillBored.Geo.Polygon{coords: coords} ->
        data =
          Geo.WKT.encode!(%Geo.Polygon{
            coordinates: [
              Enum.map(coords, fn %BillBored.Geo.Point{lat: lat, long: long} ->
                {long, lat}
              end)
            ],
            srid: 4326
          })

        [<<IO.iodata_length(data)::int32>> | data]

      # TODO
      %x{} = geom when x in [Geo.Point, Geo.Polygon] ->
        data = Geo.WKT.encode!(geom)
        [<<IO.iodata_length(data)::int32>> | data]
    end
  end

  @impl true
  def decode(:reference) do
    quote location: :keep do
      <<len::int32, wkb::binary-size(len)>> ->
        %Geo.Point{coordinates: {long, lat}} = Geo.WKB.decode!(wkb)
        %BillBored.Geo.Point{lat: lat, long: long}
    end
  end

  def decode(:copy) do
    quote location: :keep do
      <<len::int32, wkb::binary-size(len)>> ->
        %Geo.Point{coordinates: {long, lat}} = Geo.WKB.decode!(:binary.copy(wkb))
        %BillBored.Geo.Point{lat: lat, long: long}
    end
  end
end
