defmodule BillBored.Covid.Cases do
  import Ecto.Query

  alias BillBored.Covid.Case, as: CovidCase
  alias BillBored.Covid.Location, as: CovidLocation

  def list_per_country(datetime) do
    timeslot = Timex.beginning_of_day(datetime) |> Timex.to_unix()

    from(c in CovidCase,
      join: l in assoc(c, :location),
      where: l.scope == "country" and c.timeslot == ^timeslot,
      order_by: [asc: c.id],
      preload: [location: l]
    )
    |> Repo.all()
  end

  def list_per_region(datetime) do
    timeslot = Timex.beginning_of_day(datetime) |> Timex.to_unix()

    from(c in CovidCase,
      join: l in assoc(c, :location),
      where: l.scope in ["state", "county", "city"] and c.timeslot == ^timeslot,
      order_by: [asc: c.id],
      preload: [location: l]
    )
    |> Repo.all()
  end

  def get_worldwide_summary(datetime) do
    timeslot = Timex.beginning_of_day(datetime) |> Timex.to_unix()

    from(c in CovidCase,
      join: l in assoc(c, :location),
      where: l.scope == "country" and c.timeslot == ^timeslot,
      select: %{
        source_url: nil,
        cases: sum(coalesce(c.cases, 0)),
        active_cases: sum(coalesce(c.active_cases, 0)),
        deaths: sum(coalesce(c.deaths, 0)),
        recoveries: sum(coalesce(c.recoveries, 0))
      }
    )
    |> Repo.one()
    |> Map.put(:location, %CovidLocation{
      scope: "world",
      country_code: "",
      region: "",
      location: %BillBored.Geo.Point{long: 0, lat: 0}
    })
  end

  def get_latest_date() do
    from(c in CovidCase,
      select: fragment("date_trunc('day', ?)", c.datetime),
      order_by: [desc: c.datetime],
      limit: 1
    )
    |> Repo.one()
    |> DateTime.from_naive!("Etc/UTC")
  end

  def get_info() do
    covid_info =
      from(e in BillBored.KVEntries.CovidInfo, where: e.key == "covid_info")
      |> Repo.one()

    case covid_info do
      nil -> %{}
      %{value: value} -> value
    end
  end
end
