defmodule Web.NotificationController do
  use Web, :controller
  alias BillBored.Notifications

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def index(conn, params, user_id) do
    notifications = Notifications.index(user_id, params)
    render(conn, "index.json", data: notifications)
  end

  def update(conn, params, user_id) do
    if Map.get(params, "mark_all_read") do
      Notifications.mark_as_read(user_id, :all)
    else
      id = Map.get(params, "notification_read", 0)
      Notifications.mark_as_read(user_id, [id])
    end

    send_resp(conn, :ok, [])
  end
end
