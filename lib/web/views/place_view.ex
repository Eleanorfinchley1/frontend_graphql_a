defmodule Web.PlaceView do
  use Web, :view

  def render("show.json", %{place: place}) do
    place
    |> Map.take([:name, :vicinity, :address, :icon, :place_id])
    |> Map.put(:location, render_one(place.location, Web.LocationView, "show.json"))
    |> Map.put(:types, Enum.map(place.types, & &1.name))
  end
end
