defmodule BillBored.EventSynchronizations do
  @moduledoc false

  import Ecto.Query
  import Geo.PostGIS, only: [st_dwithin_in_meters: 3]

  alias BillBored.EventSynchronization

  def create(attrs) do
    %EventSynchronization{}
    |> EventSynchronization.changeset(attrs)
    |> Repo.insert()
  end

  def update(event_synchronization, attrs) do
    event_synchronization
    |> EventSynchronization.changeset(attrs)
    |> Repo.update()
  end

  def complete(%EventSynchronization{status: "pending"} = event_synchronization) do
    __MODULE__.update(event_synchronization, %{status: "completed"})
  end

  def fail(%EventSynchronization{status: "pending"} = event_synchronization) do
    __MODULE__.update(event_synchronization, %{status: "failed"})
  end

  def count_recent(provider, {%BillBored.Geo.Point{} = point, radius}, since) do
    from(es in EventSynchronization,
      select: %{
        pending_count: sum(fragment("(? = ?)::int", es.status, "pending")),
        failed_count: sum(fragment("(? = ?)::int", es.status, "failed")),
        completed_count: sum(fragment("(? = ?)::int", es.status, "completed"))
      },
      where:
        es.event_provider == ^provider and
          ^radius < 2.0 * es.radius and
          st_dwithin_in_meters(es.location, ^point, es.radius) and
          es.started_at >= ^since,
      group_by: es.event_provider
    )
    |> Repo.one()
    |> case do
      nil -> %{pending_count: 0, failed_count: 0, completed_count: 0}
      result -> result
    end
  end

  def delete_old(provider, to) do
    from(es in EventSynchronization,
      where: es.event_provider == ^provider and es.started_at < ^to
    )
    |> Repo.delete_all()
  end
end
