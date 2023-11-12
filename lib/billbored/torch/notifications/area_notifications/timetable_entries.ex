defmodule BillBored.Torch.Notifications.AreaNotifications.TimetableEntries do
  @moduledoc false

  import Ecto.Query
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.Notifications.AreaNotifications.TimetableEntry

  @pagination [page_size: 15]
  @pagination_distance 5

  def create(attrs) do
    Repo.insert(TimetableEntry.changeset(%TimetableEntry{}, attrs))
  end

  def update(timetable_entry, attrs) do
    Repo.update(TimetableEntry.changeset(timetable_entry, attrs))
  end

  def get!(id) do
    Repo.get!(TimetableEntry, id)
  end

  def delete(%TimetableEntry{} = timetable_entry) do
    Repo.delete(timetable_entry)
  end

  def get_category_names() do
    Repo.all(BillBored.InterestCategory)
    |> Enum.map(&(&1.name))
  end

  def paginate(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <-
           Filtrex.parse_params(
             filter_config(:area_notifications),
             params["timetable_entry"] || %{}
           ),
         %Scrivener.Page{} = page <- do_paginate(filter, params) do
      {:ok,
       %{
         timetable_entries: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate(filter, params) do
    TimetableEntry
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  defp filter_config(:area_notifications) do
    defconfig do
      number(:id)
      datetime(:inserted_at)
    end
  end
end
