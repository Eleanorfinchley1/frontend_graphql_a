defmodule Web.GeoController do
  use Web, :controller

  alias BillBored.Place.GoogleApi.Places, as: PlacesAPI

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def show(conn, %{"location" => %{"coordinates" => [lat, lng], "type" => _type}}, _user_id) do
    case PlacesAPI.search(lat, lng) do
      {:ok, places} ->
        place =
          places
          |> Enum.sort_by(& &1.distance)
          |> hd()

        render(conn, "show.json", %{place: place})

      :error ->
        send_resp(conn, 404, [])
    end
  end
end
