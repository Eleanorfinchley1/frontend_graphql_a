defmodule Web.Torch.TimetableEntryController do
  use Web, :controller

  alias BillBored.Torch.Notifications.AreaNotifications.TimetableEntries
  alias BillBored.Notifications.AreaNotifications.TimetableEntry

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    case TimetableEntries.paginate(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering timetable entries: #{inspect(error)}")
        |> redirect(to: Routes.torch_timetable_entry_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    timetable_entry = TimetableEntries.get!(id)
    render(conn, "show.html", timetable_entry: timetable_entry)
  end

  def new(conn, _params) do
    changeset = TimetableEntry.changeset(%TimetableEntry{}, %{})
    render(conn, "new.html", categories: TimetableEntries.get_category_names(), changeset: changeset)
  end

  def create(conn, %{"timetable_entry" => attrs} = _params) do
    with {:ok, timetable_entry} <- TimetableEntries.create(attrs) do
      render(conn, "show.html", timetable_entry: timetable_entry)
    else
      {:error, %{valid?: false} = changeset} ->
        render(conn, "new.html", categories: TimetableEntries.get_category_names(), changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    timetable_entry = TimetableEntries.get!(id)
    changeset = Ecto.Changeset.change(timetable_entry)
    render(conn, "edit.html", categories: TimetableEntries.get_category_names(), timetable_entry: timetable_entry, changeset: changeset)
  end

  def update(conn, %{"id" => id, "timetable_entry" => attrs} = _params) do
    timetable_entry = TimetableEntries.get!(id)

    with {:ok, timetable_entry} <- TimetableEntries.update(timetable_entry, attrs) do
      render(conn, "show.html", timetable_entry: timetable_entry)
    else
      {:error, %{valid?: false} = changeset} ->
        render(conn, "edit.html", categories: TimetableEntries.get_category_names(), timetable_entry: timetable_entry, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    timetable_entry = TimetableEntries.get!(id)
    with {:ok, _timetable_entry} <- TimetableEntries.delete(timetable_entry) do
      conn
      |> put_flash(:info, "Timetable entry #{id} deleted successfully.")
      |> redirect(to: Routes.torch_timetable_entry_path(conn, :index))
    else
      error ->
        conn
        |> put_flash(:error, "Failed to delete timetable entry #{id}: #{inspect(error)}")
        |> redirect(to: Routes.torch_timetable_entry_path(conn, :index))
    end
  end
end
