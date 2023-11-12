defmodule Web.OffersChannel do
  use Web, :channel
  use Web.Channels.ChannelTasks

  import BillBored.ServiceRegistry, only: [service: 1]
  require Logger

  @post_types [:offer]

  @impl true
  def join(
        "offers",
        %{
          "geometry" => %{"type" => "Point"} = geometry,
          "radius" => radius
        },
        %{assigns: %{user: user}} = socket
      ) do
    %Geo.Point{coordinates: {lat, long}} = Geo.JSON.decode!(geometry)

    socket =
      socket
      |> assign(:location, %BillBored.Geo.Point{lat: lat, long: long})
      |> assign(:radius, radius)
      |> maybe_assign_ignore_set()
      |> run_markers_fetch()

    Phoenix.PubSub.subscribe(Web.PubSub, "user_blocks:#{user.id}")

    {:ok, socket}
  end

  def join("offers", _params, _socket) do
    {:error, %{"details" => "invalid params, need geometry(point) and radius"}}
  end

  @impl true
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

    socket = run_markers_fetch(socket)

    {:reply, :ok, socket}
  end

  @impl true
  def start_task("markers:fetch", {search_location, filter}, socket) do
    task =
      Task.async(fn ->
        markers = service(BillBored.CachedPosts).list_markers(search_location, filter)
        rendered_markers = Phoenix.View.render_many(markers, Web.PostView, "marker.json", as: :marker)

        %{markers: rendered_markers}
      end)

    {:ok, task, socket}
  end

  @impl true
  def handle_task("markers:fetch", :completed, result, socket) do
    push(socket, "markers", result)
    {:noreply, socket}
  end

  def handle_task("markers:fetch", :cancelled, _params, socket) do
    {:noreply, socket}
  end

  def handle_task(_name, :completed, result, socket) do
    {:reply, result, socket}
  end

  def handle_task(_name, :cancelled, _params, socket) do
    {:reply, {:error, %{reason: :cancelled}}, socket}
  end

  intercept(["post:new", "post:update", "post:delete"])

  @impl true
  def handle_out(
        event,
        %{author: %{id: author_id}} = msg,
        %{assigns: %{ignore_set: ignore_set}} = socket
      ) do
    unless MapSet.member?(ignore_set, author_id) do
      maybe_push(event, msg, socket)
    else
      {:noreply, socket}
    end
  end

  def handle_out(event, msg, socket) do
    maybe_push(event, msg, socket)
  end

  defp maybe_push(
         event,
         %{
           location: %BillBored.Geo.Point{} = post_location,
           payload: payload,
           post_type: post_type
         },
         %Phoenix.Socket{
           assigns: %{
             location: %BillBored.Geo.Point{} = user_location,
             radius: radius
           }
         } = socket
       ) do
    if BillBored.Geo.within?(post_location, user_location, radius) and (post_type in @post_types) do
      push(socket, event, payload)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:user_blocks_update, %{id: user_id}},
        %{assigns: %{user: %{id: user_id}}} = socket
      ) do
    {:noreply, maybe_assign_ignore_set(socket)}
  end

  def handle_info(msg, socket) do
    handle_info_tasks(msg, socket)
  end

  defp maybe_assign_ignore_set(%{assigns: %{user: user}} = socket) do
    blockers_ids = BillBored.User.Blocks.get_blockers_of(user) |> Enum.map(& &1.id)
    blocked_ids = BillBored.User.Blocks.get_blocked_by(user) |> Enum.map(& &1.id)

    ignore_set = MapSet.new(blocked_ids ++ blockers_ids)

    case MapSet.size(ignore_set) do
      0 ->
        %{socket | assigns: Map.delete(socket.assigns, :ignore_set)}

      _ ->
        assign(socket, :ignore_set, ignore_set)
    end
  end

  defp run_markers_fetch(%{assigns: %{user: user, location: location, radius: radius}} = socket) do
    filter = %{
      types: @post_types,
      for_id: user.id
    }

    run_exclusive_task(socket, "markers:fetch", {{location, radius}, filter})
  end

  defp run_markers_fetch(%{assigns: assigns} = socket) do
    Logger.warn(
      "Can't push markers due to incomplete assigns: location: #{inspect(assigns[:location])}, radius: #{
        inspect(assigns[:radius])
      }"
    )

    socket
  end
end
