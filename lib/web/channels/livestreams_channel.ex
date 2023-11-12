defmodule Web.LivestreamsChannel do
  use Web, :channel

  alias BillBored.User

  # TODO try catch
  def join(
        "livestreams",
        %{"geometry" => %{"type" => "Point"} = geometry, "radius" => radius},
        socket
      ) do
    %Geo.Point{coordinates: {lat, long}} = Geo.JSON.decode!(geometry)

    socket =
      socket
      |> assign(:location, %BillBored.Geo.Point{lat: lat, long: long})
      |> assign(:radius, radius)

    {:ok, socket}
  end

  def join("livestreams", _params, _socket) do
    {:error, %{"details" => "invalid params, need geometry(point) and radius"}}
  end

  def handle_in(
        "livestreams:list",
        %{"geometry" => geometry} = params,
        %{assigns: %{user: %User{id: user_id}}} = socket
      ) do
    rendered_livestreams =
      geometry
      |> Geo.JSON.decode!()
      |> case do
        # TODO
        %Geo.Point{coordinates: {lat, long}} ->
          radius = params["radius"] || socket.assigns.radius

          BillBored.Livestreams.list_by_location(
            %BillBored.Geo.Point{lat: lat, long: long},
            %{radius_in_m: radius, for_id: user_id}
          )

        # TODO
        %Geo.Polygon{coordinates: coords} ->
          polygon = %BillBored.Geo.Polygon{
            coords:
              Enum.map(coords, fn {lat, long} ->
                %BillBored.Geo.Point{lat: lat, long: long}
              end)
          }

          BillBored.Livestreams.list_by_location(polygon, %{for_id: user_id})
      end
      |> Phoenix.View.render_many(Web.LivestreamView, "livestream.json")

    {:reply, {:ok, %{"livestreams" => rendered_livestreams}}, socket}
  end

  # TODO try catch
  def handle_in("update", updates, socket) do
    socket =
      case updates["geometry"] do
        %{"type" => "Point"} = new_geometry ->
          %Geo.Point{coordinates: {lat, long}} = Geo.JSON.decode!(new_geometry)
          assign(socket, :location, %BillBored.Geo.Point{lat: lat, long: long})

        _other ->
          socket
      end

    socket =
      if new_radius = updates["radius"] do
        assign(socket, :radius, new_radius)
      else
        socket
      end

    {:reply, :ok, socket}
  end

  # TODO very naive approach, optimize
  intercept(["livestream:new", "livestream:over", "livestream:recording:new"])

  def handle_out(
        "livestream:new",
        %{
          location: %BillBored.Geo.Point{} = livestream_location,
          payload: payload
        },
        %Phoenix.Socket{
          assigns: %{location: %BillBored.Geo.Point{} = user_location, radius: radius}
        } = socket
      ) do
    if BillBored.Geo.within?(livestream_location, user_location, radius) do
      push(socket, "livestream:new", payload)
    end

    {:noreply, socket}
  end

  def handle_out(
        "livestream:over",
        %{
          location: %BillBored.Geo.Point{} = livestream_location,
          payload: payload
        },
        %Phoenix.Socket{
          assigns: %{location: %BillBored.Geo.Point{} = user_location, radius: radius}
        } = socket
      ) do
    if BillBored.Geo.within?(livestream_location, user_location, radius) do
      push(socket, "livestream:over", payload)
    end

    {:noreply, socket}
  end

  def handle_out(
        "livestream:recording:new",
        %{
          location: %BillBored.Geo.Point{} = livestream_location,
          payload: payload
        },
        %Phoenix.Socket{
          assigns: %{location: %BillBored.Geo.Point{} = user_location, radius: radius}
        } = socket
      ) do
    if BillBored.Geo.within?(livestream_location, user_location, radius) do
      push(socket, "livestream:recording:new", payload)
    end

    {:noreply, socket}
  end
end
