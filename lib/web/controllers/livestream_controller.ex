defmodule Web.LivestreamController do
  use Web, :controller
  alias BillBored.{Users, Livestreams, Livestream}
  import BillBored.Geo, only: [fake_place: 1]
  import BillBored.Helpers, only: [decode_base64_id: 2]

  action_fallback Web.FallbackController

  defp current_user_id!(%Plug.Conn{assigns: assigns}) do
    Map.fetch!(assigns, :user_id)
  end

  def create(conn, %{"safe_location?" => sl} = params)
      when sl in [true, "true", 1, "1"] do
    coords = params["location"]["coordinates"]

    case fake_place(coords) do
      {:ok, %BillBored.Place{location: %BillBored.Geo.Point{lat: lat, long: long}}} ->
        params = put_in(params["location"]["coordinates"], [lat, long])
        create(conn, %{params | "safe_location?" => false})

      :error ->
        conn
        |> put_status(400)
        |> json(%{success: false, reason: "Cannot generate fake coordinates"})
    end
  end

  def create(conn, params) do
    with {:ok, %Livestream{} = livestream} <-
           Livestreams.create(params, owner_id: current_user_id!(conn)) do
      render(conn, "livestream_created.json", livestream: livestream)
    end
  end

  def publish(conn, %{"id" => livestream_id}) do
    BillBored.Livestreams.delayed_publish(livestream_id, current_user_id!(conn))
    send_resp(conn, 200, [])
  end

  def mark_recorded(conn, %{"id" => livestream_id}) do
    # sets livestream.recorded? to true and pushes "livestream:recording:new" to socket
    %BillBored.Livestream{location: %BillBored.Geo.Point{} = livestream_location} =
      livestream = Livestreams.mark_recorded(livestream_id, current_user_id!(conn))

    rendered_livestream = Web.LivestreamView.render("livestream.json", %{livestream: livestream})

    message = %{
      location: livestream_location,
      payload: rendered_livestream
    }

    # TODO use job queue
    spawn(fn ->
      :timer.sleep(:timer.seconds(50))
      Web.Endpoint.broadcast("livestreams", "livestream:recording:new", message)
    end)

    send_resp(conn, 200, [])
  end

  def delete_livestream(conn, %{"id" => livestream_id}) do
    if livestream = Livestreams.get(livestream_id) do
      user = Users.get(current_user_id!(conn))

      if livestream.owner_id == user.id || user.is_superuser do
        Livestreams.delete(livestream)
        send_resp(conn, 204, [])
      else
        send_resp(conn, 403, [])
      end
    else
      send_resp(conn, 204, [])
    end
  end

  def find_user_livestreams(conn, %{"userid" => id}) do
    id = String.to_integer(id)

    if current_user_id!(conn) == id do
      find_user_livestreams(conn, %{})
    else
      user = Users.get(current_user_id!(conn))

      if user.is_superuser do
        ls = Livestreams.get_livestreams_by_userid(id)
        render(conn, "livestreams.json", livestreams: ls)
      else
        send_resp(conn, 403, [])
      end
    end
  end

  def find_user_livestreams(conn, _attrs) do
    ls = Livestreams.get_livestreams_by_userid(current_user_id!(conn))
    render(conn, "livestreams.json", livestreams: ls)
  end

  def show(conn, %{"id" => livestream_id}) do
    livestream =
      livestream_id
      |> decode_base64_id(%{schema: Livestream})
      |> Livestreams.get_livestream!()

    render(conn, "show.html", livestream: livestream)
  end
end
