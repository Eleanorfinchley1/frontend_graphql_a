defmodule BillBored.Place.GoogleApi.Places do
  import Ecto.Query
  import Geo.PostGIS, only: [st_distance_in_meters: 2]
  # import Distance.GreatCircle, only: [distance: 2]
  alias BillBored.Place
  require Logger

  @doc """
  Searches for the places.

  ## Arguments

    * `%{lat: latitude, long: longitude}` — search center;
    * `radius` — search radius.

  ## Options

    * `ignored_types` (`[string]`, `[]`);

    * `min_distance` (`non_neg_integer`, `0`) — minimum distance to the point.
  """
  def search(coord, radius, opts \\ %{}) do
    with {_, []} <- {:cache, search_in_db(coord, radius, opts)},
         {_, []} <- {:google, search_in_google(coord, radius, opts)},
         {_, []} <- {:google, search_in_google(coord, radius + 500, opts)},
         {_, []} <- {:google, search_in_google(coord, radius + 1000, opts)},
         {_, []} <- {:google, search_in_google(coord, radius + 2000, opts)},
         {_, []} <- {:google, search_in_google(coord, radius + 5000, opts)} do
      :error
    else
      {:google, results} ->
        {_, types} =
          Repo.insert_all(
            Place.Type,
            results |> Enum.flat_map(& &1["types"]) |> Enum.uniq() |> Enum.map(&%{name: &1}),
            on_conflict: {:replace, [:name]},
            conflict_target: :name,
            returning: true
          )

        types_by_name = types |> Enum.map(&{&1.name, &1}) |> Enum.into(%{})

        results =
          results
          |> Enum.map(fn result ->
            %{
              "vicinity" => vicinity,
              "geometry" => %{"location" => %{"lat" => lat, "lng" => lng}}
            } = result

            {result,
             Place.changeset(
               %Place{
                 source: "google maps",
                 location: %BillBored.Geo.Point{lat: lat, long: lng},
                 address: vicinity
               },
               result
             )}
          end)
          |> Enum.filter(fn {_result, changeset} -> changeset.valid? end)
          |> Enum.map(fn {result, changeset} ->
            {result, Ecto.Changeset.apply_changes(changeset)}
          end)

        now = DateTime.utc_now()

        data =
          Enum.map(
            results,
            fn {_result, place} ->
              attrs =
                Map.take(place, [
                  :source,
                  :name,
                  :location,
                  :place_id,
                  :address,
                  :icon,
                  :vicinity
                ])

              attrs |> Map.put(:inserted_at, now) |> Map.put(:updated_at, now)
            end
          )

        {_count, places} =
          Repo.insert_all(Place, data,
            on_conflict: {:replace, [:name, :location, :address, :icon, :vicinity, :updated_at]},
            conflict_target: :place_id,
            returning: true
          )

        only_results = Enum.map(results, fn {result, _place} -> result end)

        typeships =
          places
          |> Enum.zip(only_results)
          |> Enum.flat_map(fn {%Place{id: place_id}, %{"types" => types}} ->
            Enum.map(types, fn type_name ->
              %Place.Type{id: type_id} = Map.fetch!(types_by_name, type_name)
              %{type_id: type_id, place_id: place_id}
            end)
          end)

        Repo.insert_all(Place.Typeship, typeships, on_conflict: :nothing)

        places =
          places
          |> Enum.zip(only_results)
          |> Enum.map(fn {place, %{"types" => types}} ->
            %{place | types: Enum.map(types, &%Place.Type{name: &1})}
          end)

        {:ok, filter(places, coord, opts)}

      {:cache, places} ->
        {:ok, places}
    end
  end

  defp filter(places, _coord, opts) do
    places
    # |> Enum.reject(&(&1.distance < (opts[:min_distance] || 0)))
    |> Enum.reject(fn place ->
      ignored_types = opts[:ignored_types] || []
      Enum.any?(place.types, &(&1.name in ignored_types))
    end)
  end

  defp search_in_google(%{lat: lat, long: long} = coord, radius, _opts) do
    case GoogleMaps.place_nearby({lat, long}, radius) do
      {:ok, %{"results" => results}} ->
        results

      {:error, reason} ->
        Logger.error("""
        Could not find place for the coords #{inspect(coord)}
        (#{inspect(radius)} meters radius) in Google because
        of #{inspect(reason)}.
        """)

        []

      {:error, code, reason} ->
        Logger.error("""
        Could not find place for the coords #{inspect(coord)}
        (#{inspect(radius)} meters radius) in Google because
        of #{inspect(reason)}. Code: #{code}.
        """)

        []
    end
  end

  # TODO filter ignored types
  defp search_in_db(%{lat: _lat, long: _long} = coords, max, opts) do
    min = opts[:min_distance] || 0
    point = struct!(BillBored.Geo.Point, coords)

    Place
    |> where([p], st_distance_in_meters(p.location, ^point) >= ^min)
    |> where([p], st_distance_in_meters(p.location, ^point) <= ^max)
    |> order_by(:inserted_at)
    |> limit(20)
    |> select([p], %{p | distance: st_distance_in_meters(p.location, ^point)})
    |> Repo.all()
    |> Repo.preload([:types])
  end

  # def create(result) do
  #   place =
  #     Place
  #     |> Repo.get_by(place_id: result["place_id"])
  #     |> case do
  #       nil ->
  #         %Place{}
  #         |> Place.changeset(%{
  #           name: result["name"],
  #           icon: result["icon"],
  #           place_id: result["place_id"],
  #           vicinity: Map.get(result, "vicinity", ""),
  #           location: %Geo.Point{
  #             coordinates:
  #               {result["geometry"]["location"]["lat"], result["geometry"]["location"]["lng"]},
  #             srid: 4326
  #           }
  #         })
  #         |> Repo.insert!()

  #       place ->
  #         place
  #     end

  #   types =
  #     Map.get(result, "types", [])
  #     |> Enum.map(fn type ->
  #       type =
  #         Place.Type
  #         |> Repo.get_by(name: type)
  #         |> case do
  #           nil ->
  #             %Place.Type{name: type}
  #             |> Repo.insert!()

  #           type ->
  #             type
  #         end

  #       %Place.Typeship{place_id: place.id, type_id: type.id}
  #       |> Repo.insert(on_conflict: :nothing)

  #       type
  #     end)

  #   Map.put(place, :types, types)
  # end
end
