defmodule Web.LocationView do
  use Web, :view

  def render("show.json", %{location: location}) do
    %BillBored.Geo.Point{lat: lat, long: long} = location

    %{
      type: "Point",
      coordinates: [lat, long],
      crs: %{
        type: "name",
        properties: %{
          name: "EPSG:4326"
        }
      }
    }
  end

  def render("coordinates.json", %{location: location}) do
    %BillBored.Geo.Point{lat: lat, long: long} = location
    %{longitude: long, latitude: lat}
  end
end
