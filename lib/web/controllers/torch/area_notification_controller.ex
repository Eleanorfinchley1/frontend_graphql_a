defmodule Web.Torch.AreaNotificationController do
  use Web, :controller

  alias BillBored.Torch.Notifications.AreaNotificationDecorator
  alias BillBored.Torch.Notifications.AreaNotifications

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    case AreaNotifications.paginate_area_notifications(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering area notifications: #{inspect(error)}")
        |> redirect(to: Routes.torch_area_notification_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    area_notification = AreaNotifications.get!(id)
    render(conn, "show.html", area_notification: area_notification)
  end

  def new(conn, _params) do
    changeset = AreaNotificationDecorator.changeset(%AreaNotificationDecorator{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"area_notification_decorator" => attrs} = _params) do
    with changeset <- AreaNotificationDecorator.changeset(%AreaNotificationDecorator{}, attrs),
         {:ok, decorator} <- Ecto.Changeset.apply_action(changeset, :create),
         {:ok, area_notification} <- AreaNotifications.create(decorator) do
      match_data = BillBored.Notifications.AreaNotifications.MatchData.new(area_notification)
      Web.AreaNotificationChannel.notify(area_notification, match_data)
      render(conn, "show.html", area_notification: area_notification)
    else
      {:error, %{valid?: false} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    area_notification = AreaNotifications.get!(id)
    with {:ok, _area_notification} <- AreaNotifications.delete(area_notification) do
      conn
      |> put_flash(:info, "Area notification #{id} deleted successfully.")
      |> redirect(to: Routes.torch_area_notification_path(conn, :index))
    else
      error ->
        conn
        |> put_flash(:error, "Failed to delete area notification #{id}: #{inspect(error)}")
        |> redirect(to: Routes.torch_area_notification_path(conn, :index))
    end
  end
end
