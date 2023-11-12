defmodule Covid.DataScraper do
  import Ecto.Query
  require Logger

  alias BillBored.Covid.Case, as: CovidCase
  alias BillBored.Covid.Location, as: CovidLocation

  @snapshot_url "https://coronadatascraper.com/data.json"

  @country_aliases %{
    "US" => "USA"
  }

  @country_locations %{
    "USA" => %BillBored.Geo.Point{long: -120.740135, lat: 47.751076},
    "CAN" => %BillBored.Geo.Point{long: -106.3467712, lat: 56.1303673},
    "CHN" => %BillBored.Geo.Point{long: 116.363625, lat: 39.913818}
  }

  def import_snapshot() do
    json =
      try do
        Logger.info(
          "#{inspect(__MODULE__)}: downloading COVID data snapshot from #{inspect(@snapshot_url)}"
        )

        %HTTPoison.Response{body: body, status_code: 200} = HTTPoison.get!(@snapshot_url)
        Jason.decode!(body)
      catch
        e ->
          Logger.error("Failed to download COVID snapshot: #{inspect(e)}")
          nil
      end

    import_snapshot(json)
  end

  def import_snapshot(filename) when is_binary(filename) do
    File.read!(filename)
    |> Jason.decode!()
    |> import_snapshot()
  end

  def import_snapshot(entries) when is_list(entries) do
    datetime = DateTime.utc_now()

    {locations, entries} =
      Enum.reduce(entries, {[], []}, fn entry, {locations, entries} ->
        case prepare_covid_case(entry, datetime) do
          {:ok, location, entry} ->
            {[location | locations], [entry | entries]}

          _ ->
            {locations, entries}
        end
      end)

    locations =
      locations
      |> Enum.uniq_by(fn l -> {l[:scope], l[:country_code], l[:region]} end)

    entries =
      entries
      |> Enum.uniq_by(fn e -> e[:location_id] end)

    Logger.debug(
      "#{inspect(__MODULE__)}: importing #{Enum.count(locations)} locations and #{
        Enum.count(entries)
      } COVID data entries"
    )

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:insert_locations, fn _, _ ->
        {:ok, insert_locations(locations)}
      end)
      |> Ecto.Multi.run(:insert_entries, fn _, %{insert_locations: locations} ->
        entries =
          Enum.map(entries, fn %{location_id: location_key} = e ->
            Map.put(e, :location_id, Map.get(locations, location_key))
          end)

        {:ok, insert_entries(entries)}
      end)
      |> Ecto.Multi.run(:insert_missing_countries, fn _, _ ->
        {:ok, insert_missing_country_cases(datetime)}
      end)
      |> Repo.transaction()

    with {:ok, %{insert_entries: count}} <- result do
      {:ok, count}
    end
  end

  defp insert_locations(locations) do
    locations
    |> Enum.chunk_every(1000)
    |> Enum.reduce(%{}, fn chunk, acc ->
      {_, locations} =
        Repo.insert_all(BillBored.Covid.Location, chunk,
          conflict_target: [:scope, :country_code, :region],
          on_conflict: {:replace, [:source_location]},
          returning: true
        )

      Enum.reduce(locations, acc, fn l, acc ->
        Map.put(acc, {l.scope, l.country_code, l.region}, l.id)
      end)
    end)
  end

  defp insert_entries(entries) do
    entries
    |> Enum.chunk_every(1000)
    |> Enum.reduce(0, fn chunk, acc ->
      {count, _cases} =
        Repo.insert_all(BillBored.Covid.Case, chunk,
          conflict_target: [:timeslot, :location_id],
          on_conflict:
            {:replace,
             [:datetime, :timeslot, :location_id, :cases, :deaths, :recoveries, :active_cases]}
        )

      acc + count
    end)
  end

  defp prepare_covid_case(entry, datetime) do
    timeslot = Timex.beginning_of_day(datetime) |> Timex.to_unix()

    {scope, region_parts} =
      Enum.reduce(["state", "county", "city"], {"country", []}, fn k, {scope, parts} ->
        if part = entry[k] do
          {k, [part | parts]}
        else
          {scope, parts}
        end
      end)

    {lon, lat} =
      case entry["coordinates"] do
        nil -> {0, 0}
        [lon, lat] -> fix_coordinates(entry["country"], scope, lon, lat)
      end

    country_code = Map.get(@country_aliases, entry["country"], entry["country"])
    region = Enum.reverse(region_parts) |> Enum.join(", ")

    location = %{
      country_code: country_code,
      country: Iso3166.get(entry["country"]),
      scope: scope,
      state: entry["state"],
      county: entry["county"],
      city: entry["city"],
      region: region,
      source_population: try_parse_integer(entry["population"]),
      source_location: %BillBored.Geo.Point{long: lon, lat: lat}
    }

    entry = %{
      location_id: {scope, country_code, region},
      datetime: datetime,
      timeslot: timeslot,
      source_url: entry["url"],
      cases: try_parse_integer(entry["cases"]) || 0,
      deaths: try_parse_integer(entry["deaths"]),
      recoveries: try_parse_integer(entry["recovered"]),
      active_cases: try_parse_integer(entry["active"])
    }

    {:ok, location, entry}
  end

  defp try_parse_integer(str) when is_binary(str) do
    case String.to_integer(str) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp try_parse_integer(val) when is_float(val), do: trunc(val)
  defp try_parse_integer(val) when is_integer(val), do: val
  defp try_parse_integer(_), do: nil

  defp fix_coordinates("RUS", "country", _lon, _lat), do: {37.6155586, 55.7522202}
  defp fix_coordinates(_country, _scope, lon, lat), do: {lon, lat}

  defp insert_missing_country_cases(datetime) do
    timeslot = Timex.beginning_of_day(datetime) |> Timex.to_unix()

    country_query =
      from(c in CovidCase,
        join: l in assoc(c, :location),
        where: c.timeslot == ^timeslot and l.scope == "country",
        select: l.country_code,
        distinct: true
      )

    missing_countries =
      from(c in CovidCase,
        join: l in assoc(c, :location),
        left_join: l2 in subquery(country_query),
        on: l2.country_code == l.country_code,
        where: c.timeslot == ^timeslot and l.scope != "country" and is_nil(l2.country_code),
        select: %{
          country_code: l.country_code,
          scope: "country",
          region: ""
        },
        distinct: true
      )
      |> Repo.all()
      |> Enum.map(fn %{country_code: country_code} = c ->
        Map.merge(c, %{
          country: Iso3166.get(country_code),
          location: Map.get(@country_locations, country_code)
        })
      end)

    {_, countries} =
      Repo.insert_all(CovidLocation, missing_countries,
        conflict_target: [:scope, :country_code, :region],
        on_conflict: {:replace, [:region]},
        returning: [:country_code, :id]
      )

    Enum.each(countries, fn %{country_code: country_code, id: location_id} ->
      state_locations =
        from(l in CovidLocation,
          where: l.country_code == ^country_code and l.scope == "state"
        )
        |> Repo.all()

      states = Enum.map(state_locations, & &1.state)

      county_locations =
        from(l in CovidLocation,
          where:
            l.country_code == ^country_code and l.scope == "county" and not (l.state in ^states)
        )
        |> Repo.all()

      counties = Enum.map(county_locations, & &1.county)

      city_locations =
        from(l in CovidLocation,
          where:
            l.country_code == ^country_code and l.scope == "city" and
              not (l.state in ^states and l.county in ^counties)
        )
        |> Repo.all()

      location_ids =
        (state_locations ++ county_locations ++ city_locations)
        |> Enum.map(& &1.id)

      covid_case =
        from(c in CovidCase,
          join: l in assoc(c, :location),
          where: c.timeslot == ^timeslot and l.id in ^location_ids,
          group_by: 1,
          select: %{
            location_id: fragment("?::bigint", ^location_id),
            cases: sum(coalesce(c.cases, 0)),
            deaths: sum(coalesce(c.deaths, 0)),
            recoveries: sum(coalesce(c.recoveries, 0)),
            active_cases: sum(coalesce(c.active_cases, 0))
          }
        )
        |> Repo.one()
        |> Map.merge(%{datetime: datetime, timeslot: timeslot})

      Repo.insert!(CovidCase.changeset(%CovidCase{}, covid_case))
    end)

    nil
  end
end
