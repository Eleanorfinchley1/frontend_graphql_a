defmodule Web.DeviceController do
  use Web, :controller
  alias BillBored.{Users, User}

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def index(conn, params, user_id) do
    devices = Users.index_devices(user_id, params)
    render(conn, "index.json", data: devices)
  end

  def show(conn, %{"id" => id}, _opts) do
    Users.get_device(id: id)
    |> Repo.preload([:user])
    |> case do
      %User.Device{} = device ->
        render(conn, "show.json", %{device: device})

      _ ->
        send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))
    end
  end

  def create(conn, params, user_id) do
    Map.put(params, "user_id", user_id)
    |> Users.create_device()
    |> case do
      {:ok, device} ->
        render(conn, "page.json", device: Repo.preload(device, [:user]))

      {:error, _} ->
        send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))
    end
  end

  def update(conn, %{"id" => id} = params, user_id) do
    params = Map.put(params, "user_id", user_id)

    case Users.create_or_update_device(id, params) do
      {:ok, device} ->
        render(conn, "page.json", device: Repo.preload(device, [:user]))

      {:error, _} ->
        send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))
    end
  end

  def delete(conn, %{"id" => id}, _opts) do
    Users.get_device(id: id)
    |> case do
      %User.Device{} = device ->
        Users.delete_device(device)
        send_resp(conn, :ok, [])

      _ ->
        send_resp(conn, 404, Jason.encode!(%{details: "Not found."}, pretty: true))
    end
  end
end
