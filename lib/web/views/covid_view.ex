defmodule Web.CovidView do
  use Web, :view

  @fields [
    :cases,
    :deaths,
    :recoveries,
    :active_cases
  ]

  def render("index.json", %{data: cases, updated_at: updated_at} = object) do
    result = %{
      updated_at: DateTime.to_iso8601(updated_at),
      cases: render_many(cases, __MODULE__, "show.json")
    }

    result =
      if worldwide = object[:worldwide] do
        Map.put(result, :worldwide, render_one(worldwide, __MODULE__, "show.json"))
      else
        result
      end

    if info = object[:info] do
      Map.put(result, :info, info)
    else
      result
    end
  end

  def render("show.json", %{covid: %{location: location} = object}) do
    location_point =
      location.location || location.source_location || %BillBored.Geo.Point{long: 0, lat: 0}

    Map.take(object, @fields)
    |> Map.put(:country, location.country || location.country_code)
    |> Map.put(:location, render_one(location_point, Web.LocationView, "show.json"))
    |> Map.put(:source_url, object.source_url || "")
    |> Map.put(:region, location.region || "")
    |> Map.put(:population, location.population || location.source_population || 0)
  end
end
