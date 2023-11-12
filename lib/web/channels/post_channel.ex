defmodule Web.PostChannel do
  use Web, :channel
  use Web.Channels.ChannelTasks

  import BillBored.ServiceRegistry, only: [service: 1]
  require Logger

  # TODO put in a try catch block
  @impl true
  def join(
        "posts",
        %{
          "geometry" => %{"type" => "Point"} = geometry,
          "radius" => radius,
          "post_types" => post_types
        } = params,
        %{assigns: %{user: user}} = socket
      ) do
    %Geo.Point{coordinates: {lat, long}} = Geo.JSON.decode!(geometry)

    socket =
      socket
      |> assign(:location, %BillBored.Geo.Point{lat: lat, long: long})
      |> assign(:radius, radius)
      |> assign(:post_types, process_raw_post_types(post_types))
      |> maybe_assign_ignore_set()
      |> maybe_enable_markers(params)
      |> maybe_run_events_sync()
      |> maybe_run_markers_fetch()

    Phoenix.PubSub.subscribe(Web.PubSub, "user_blocks:#{user.id}")

    {:ok, socket}
  end

  def join("posts", _params, _socket) do
    {:error, %{"details" => "invalid params, need geometry(point), radius, and post_types"}}
  end

  supported_post_types = [
    {"vote", :vote},
    {"poll", :poll},
    {"regular", :regular},
    {"event", :event}
  ]

  @spec process_raw_post_type(String.t()) :: atom
  defp process_raw_post_type(raw_post_type)

  Enum.map(supported_post_types, fn {string_post_type, atom_post_type} ->
    defp process_raw_post_type(unquote(string_post_type)), do: unquote(atom_post_type)
  end)

  defp process_raw_post_types(post_types) do
    Enum.map(post_types, fn post_type ->
      process_raw_post_type(post_type)
    end)
  end

  # TODO find a better way
  if Mix.env() == :test do
    defp eventful_from_date_param do
      Eventful.date_range(30, ~D[2019-12-09])
    end
  else
    defp eventful_from_date_param do
      Eventful.date_range(90)
    end
  end

  @impl true
  def handle_in("posts:list", %{"geometry" => geometry} = params, socket) do
    geometry =
      case Geo.JSON.decode!(geometry) do
        %Geo.Point{coordinates: {lat, long}} ->
          %BillBored.Geo.Point{lat: lat, long: long}

        %Geo.Polygon{coordinates: coords} ->
          %BillBored.Geo.Polygon{
            coords:
              Enum.map(coords, fn {lat, long} ->
                %BillBored.Geo.Point{lat: lat, long: long}
              end)
          }
      end

    search_location =
      case geometry do
        %BillBored.Geo.Point{} = point -> {point, params["radius"] || socket.assigns.radius}
        %BillBored.Geo.Polygon{} = polygon -> polygon
      end

    new_socket =
      socket
      |> run_exclusive_task("posts:list", {search_location, params})
      |> run_exclusive_task("meetup:sync", search_location)
      |> run_exclusive_task("allevents:sync", search_location)

    {:noreply, new_socket}
  end

  # TODO put in a try catch block
  # TODO test
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

    socket =
      if new_post_types = updates["post_types"] do
        assign(socket, :post_types, process_raw_post_types(new_post_types))
      else
        socket
      end

    socket =
      socket
      |> maybe_run_events_sync()
      |> maybe_run_markers_fetch()

    # TODO remove once the ios app doesn't check for the payload anymore
    {:reply, {:ok, %{"todo" => "remove"}}, socket}
  end

  def handle_in("filter:update", %{"filter" => filter}, socket) do
    {:ok, filter} = BillBored.Posts.Filter.parse(filter, socket.assigns[:filter] || %{})

    socket =
      assign(socket, :filter, filter)
      |> maybe_run_markers_fetch()

    {:reply, :ok, socket}
  end

  def handle_in("filter:categories", params, socket) do
    params = Map.merge(%{"page_size" => 500}, params)

    %Scrivener.Page{
      entries: interests,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } = BillBored.Interests.index(params)

    categories = Enum.map(interests, fn %BillBored.Interest{hashtag: tag} -> tag end)

    {:reply,
     {:ok,
      %{
        categories: categories,
        page_number: page_number,
        page_size: page_size,
        total_entries: total_entries,
        total_pages: total_pages
      }}, socket}
  end

  # TODO test
  def handle_in("posts:statistics", %{"post_ids" => post_ids}, socket) do
    statistics = BillBored.Posts.get_statistics(post_ids, socket.assigns.user.id)
    {:reply, {:ok, %{"statistics" => statistics}}, socket}
  end

  @impl true
  def start_task("posts:list", {search_location, params}, socket) do
    task =
      Task.async(fn ->
        %Scrivener.Page{
          entries: posts,
          page_number: page_number,
          page_size: page_size,
          total_entries: total_entries,
          total_pages: total_pages
        } =
          BillBored.Posts.list_by_location(
            search_location,
            Map.merge(
              socket.assigns[:filter] || %{},
              %{
                types:
                  if raw_post_types = params["post_types"] do
                    process_raw_post_types(raw_post_types)
                  else
                    socket.assigns.post_types
                  end
              }
            ),
            params
          )

        rendered_posts =
          Phoenix.View.render_many(posts, Web.PostView, "show.json", %{
            user_id: socket.assigns.user.id
          })

        {:ok,
         %{
           posts: rendered_posts,
           page_number: page_number,
           page_size: page_size,
           total_entries: total_entries,
           total_pages: total_pages
         }}
      end)

    {:ok, task, maybe_fetch_evenftul_events(socket, search_location)}
  end

  def start_task("meetup:sync", search_location, socket) do
    task = Task.async(fn ->
      try do
        service(Meetup).synchronize_events(search_location)
      catch
        error ->
          Logger.error("Meetup sync failed: #{inspect(error)}")
          {:error, error}
      end
    end)
    {:ok, task, socket}
  end

  def start_task("allevents:sync", search_location, socket) do
    task = Task.async(fn ->
      try do
        service(Allevents).synchronize_events(search_location)
      catch
        error ->
          Logger.error("Allevents sync failed: #{inspect(error)}")
          {:error, error}
      end
    end)
    {:ok, task, socket}
  end

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
  def handle_task("meetup:sync", _status, _result, socket) do
    {:noreply, socket}
  end

  def handle_task("allevents:sync", _status, _result, socket) do
    {:noreply, socket}
  end

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

  defp maybe_fetch_evenftul_events(socket, search_location) do
    if Eventful.has_recent_searches?(search_location) do
      socket
    else
      task =
        Task.Supervisor.async_nolink(Eventful.TaskSupervisor, fn ->
          Eventful.search_events_for_location!(search_location, 1, %{
            "date" => eventful_from_date_param(),
            "page_size" => 250
          })
        end)

      assign(socket, :eventful_task_ref, task.ref)
    end
  end

  # TODO very naive approach, optimize
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
           post_type: incoming_post_type
         },
         %Phoenix.Socket{
           assigns: %{
             location: %BillBored.Geo.Point{} = user_location,
             radius: radius,
             post_types: assigned_post_types
           }
         } = socket
       ) do
    if BillBored.Geo.within?(post_location, user_location, radius) and
         subscribed_post_type?(incoming_post_type, assigned_post_types) do
      push(socket, event, payload)
    end

    {:noreply, socket}
  end

  defp subscribed_post_type?(incoming_post_type, assigned_post_types) do
    incoming_post_type in assigned_post_types
  end

  @impl true
  def handle_info(
        {ref, {search_location, _page, %HTTPoison.Response{status_code: 200, body: body}}},
        %{assigns: %{eventful_task_ref: ref}} = socket
      ) do
    Process.demonitor(ref, [:flush])

    case body do
      %{"events" => nil} ->
        :ok

      %{"events" => %{"event" => events}} ->
        persist_eventful_events(socket, events)

        if Eventful.has_more_items?(body) do
          %{"page_count" => page_count} = body
          page_count = String.to_integer(page_count)
          # https://api.eventful.com/docs/faq, can't request after 1250
          last_page = min(page_count, 4)

          Enum.each(2..last_page, fn page ->
            Task.Supervisor.async_nolink(Eventful.TaskSupervisor, fn ->
              Eventful.search_events_for_location!(search_location, page, %{
                "date" => eventful_from_date_param(),
                "page_size" => 250
              })
            end)
          end)
        end

        :ok
    end

    Eventful.record_search(search_location)

    {:noreply, %{socket | assigns: Map.delete(socket.assigns, :eventful_task_ref)}}
  end

  def handle_info(
        {ref,
         {_location, _page,
          %HTTPoison.Response{status_code: 200, body: %{"events" => %{"event" => events}}}}},
        socket
      ) do
    Process.demonitor(ref, [:flush])
    persist_eventful_events(socket, events)
    {:noreply, socket}
  end

  def handle_info(
        {ref, {_location, _page, %HTTPoison.Response{status_code: status_code} = resp}},
        socket
      ) do
    Process.demonitor(ref, [:flush])

    Logger.error("""
    Unexpected HTTP status code when fetching Eventful events: #{status_code}

    #{inspect(resp)}
    """)

    socket =
      with %{assigns: %{eventful_task_ref: ^ref}} <- socket do
        %{socket | assigns: Map.delete(socket.assigns, :eventful_task_ref)}
      end

    {:noreply, socket}
  end

  def handle_info(
        {:DOWN, ref, :process, _task_pid, {_exception, _stacktrace} = error},
        socket
      ) do
    Process.demonitor(ref, [:flush])
    Logger.error(Exception.format_exit(error))

    socket =
      with %{assigns: %{eventful_task_ref: ^ref}} <- socket do
        %{socket | assigns: Map.delete(socket.assigns, :eventful_task_ref)}
      end

    {:noreply, socket}
  end

  def handle_info(
        {:user_blocks_update, %{id: user_id}},
        %{assigns: %{user: %{id: user_id}}} = socket
      ) do
    {:noreply, maybe_assign_ignore_set(socket)}
  end

  def handle_info(msg, socket) do
    handle_info_tasks(msg, socket)
  end

  defp persist_eventful_events(socket, events) do
    try do
      posts = Eventful.persist_events(events)

      reply = %{
        posts:
          Phoenix.View.render_many(posts, Web.PostView, "show.json", %{
            user_id: socket.assigns.user.id
          })
      }

      push(socket, "posts:list:eventful", reply)
      :ok
    rescue
      error ->
        Logger.error("Failed to persist events:\n#{inspect(error)}")
        :ok
    end
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

if Mix.env() != :test do
  defp maybe_run_events_sync(%{assigns: %{location: location, radius: radius}} = socket) do
    socket
    |> maybe_fetch_evenftul_events({location, radius})
    |> run_exclusive_task("meetup:sync", {location, radius})
    |> run_exclusive_task("allevents:sync", {location, radius})
  end
end

  defp maybe_run_events_sync(socket), do: socket

  defp maybe_enable_markers(socket, %{"enable_markers" => true}) do
    assign(socket, :push_markers, true)
  end

  defp maybe_enable_markers(socket, _params) do
    assign(socket, :push_markers, false)
  end

  defp maybe_run_markers_fetch(%{assigns: %{push_markers: false}} = socket) do
    socket
  end

  defp maybe_run_markers_fetch(%{assigns: %{user: user, location: location, radius: radius}} = socket) do
    filter = Map.merge(
      socket.assigns[:filter] || %{},
      %{
        types: socket.assigns[:post_types],
        for_id: user.id
      }
    )

    run_exclusive_task(socket, "markers:fetch", {{location, radius}, filter})
  end

  defp maybe_run_markers_fetch(%{assigns: assigns} = socket) do
    Logger.warn(
      "Can't push markers due to incomplete assigns: location: #{inspect(assigns[:location])}, radius: #{
        inspect(assigns[:radius])
      }"
    )

    socket
  end
end
