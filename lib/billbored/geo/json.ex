defmodule BillBored.Geo.Json do
  def build(geo), do: do_build(geo, [])

  defp do_build({%BillBored.Geo.Point{long: lon, lat: lat}, radius}) do
    build_circle(lon, lat, radius)
  end

  defp do_build(%BillBored.Geo.Point{long: lon, lat: lat}) do
    build_marker(lon, lat)
  end

  defp do_build(geohash) when is_binary(geohash) do
    [minlat, minlon, maxlat, maxlon] = Geobox.decode_box(geohash)

    points = [
      [minlat, minlon],
      [minlat, maxlon],
      [maxlat, maxlon],
      [maxlat, minlon],
      [minlat, minlon]
    ]

    build_polygon(points)
  end

  defp do_build(list) when is_list(list) do
    Enum.map(list, &do_build/1)
  end

  defp do_build([], features) do
    build_feature_collection(features)
  end

  defp do_build([geo | rest], features) do
    do_build(rest, [do_build(geo) | features])
  end

  defp build_feature_collection(features) do
    %{
      type: "FeatureCollection",
      features: features
    }
  end

  defp build_marker(lon, lat) do
    %{
      type: "Feature",
      properties: %{
        shape: "Marker"
      },
      geometry: %{
        type: "Point",
        coordinates: [lon, lat]
      }
    }
  end

  defp build_circle(lon, lat, radius) do
    %{
      type: "Feature",
      properties: %{
        shape: "Circle",
        radius: radius
      },
      geometry: %{
        type: "Point",
        coordinates: [lon, lat]
      }
    }
  end

  defp build_polygon(points) do
    %{
      type: "Feature",
      properties: %{
        shape: "Polygon"
      },
      geometry: %{
        type: "Polygon",
        coordinates: [points]
      }
    }
  end
end
