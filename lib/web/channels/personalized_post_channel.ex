defmodule Web.PersonalizedPostChannel do
  use Web, :channel
  use Web.Channels.ChannelTasks

  import BillBored.ServiceRegistry, only: [service: 1]
  require Logger

  alias BillBored.{User, Users, Post}

  @impl true
  def join(
        "personalized",
        %{
          "geometry" => %{"type" => "Point"} = geometry,
          "radius" => radius,
          "post_types" => post_types
        } = params,
        socket
      ) do
    %Geo.Point{coordinates: {lat, long}} = Geo.JSON.decode!(geometry)

    socket =
      socket
      |> assign(:location, %BillBored.Geo.Point{lat: lat, long: long})
      |> assign(:radius, radius)
      |> assign(:post_types, process_raw_post_types(post_types))
      |> maybe_enable_markers(params)
      |> maybe_run_markers_fetch()

    {:ok, socket}
  end

  def join("personalized", _params, _socket) do
    {:error, %{"details" => "invalid params, need geometry(point), radius, and post_types"}}
  end

  supported_post_types = [
    {"vote", :vote},
    {"poll", :poll},
    {"regular", :regular},
    {"event", :event}
  ]

  @impl true
  def handle_in("posts:list", params, socket) do
    {:noreply, run_exclusive_task(socket, "posts:list", params)}
  end

  # TODO test
  def handle_in(
        "posts:statistics",
        %{"post_ids" => post_ids},
        %{assigns: %{user: %User{id: user_id}}} = socket
      ) do
    statistics = BillBored.Posts.get_statistics(post_ids, user_id)

    {:reply, {:ok, %{"statistics" => statistics}}, socket}
  end

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

    socket = maybe_run_markers_fetch(socket)

    {:reply, :ok, socket}
  end

  @impl true
  def start_task(
         "posts:list",
         %{"geometry" => geometry} = params,
         %{assigns: %{user: %User{id: user_id}, post_types: post_types}} = socket
       ) do
    task =
      Task.async(fn ->
        rendered_posts =
          geometry
          |> Geo.JSON.decode!()
          |> case do
            # TODO
            %Geo.Point{coordinates: {lat, long}} ->
              radius = params["radius"] || socket.assigns.radius

              BillBored.Posts.list_by_location(
                {%BillBored.Geo.Point{lat: lat, long: long}, radius},
                types: post_types,
                for_id: user_id
              )

            %Geo.Polygon{coordinates: coords} ->
              polygon = %BillBored.Geo.Polygon{
                coords:
                  Enum.map(coords, fn {lat, long} ->
                    %BillBored.Geo.Point{lat: lat, long: long}
                  end)
              }

              BillBored.Posts.list_by_location(polygon, types: post_types, for_id: user_id)
          end
          |> Phoenix.View.render_many(Web.PostView, "show.json", %{
            user_id: socket.assigns.user.id
          })

        {:ok, %{posts: rendered_posts}}
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

  @impl true
  def handle_info(msg, socket) do
    handle_info_tasks(msg, socket)
  end

  intercept(["post:new", "post:update"])

  @impl true
  def handle_out(
        "post:new",
        %{
          location: %BillBored.Geo.Point{} = post_location,
          payload: payload,
          post_type: incoming_post_type,
          author: %User{id: author_id}
        },
        %Phoenix.Socket{
          assigns: %{
            user: %User{id: user_id},
            location: %BillBored.Geo.Point{} = user_location,
            radius: radius,
            post_types: assigned_post_types
          }
        } = socket
      ) do
    if BillBored.Geo.within?(post_location, user_location, radius) and
         subscribed_post_type?(incoming_post_type, assigned_post_types) and
         friend_or_following?(author_id, user_id) do
      push(socket, "post:new", payload)
    end

    {:noreply, socket}
  end

  def handle_out(
        "post:update",
        %{
          location: %BillBored.Geo.Point{} = post_location,
          payload: %{"id" => post_id} = payload,
          post_type: incoming_post_type
        },
        %Phoenix.Socket{
          assigns: %{
            user: %User{id: user_id},
            location: %BillBored.Geo.Point{} = user_location,
            radius: radius,
            post_types: assigned_post_types
          }
        } = socket
      ) do
    author_id = find_author(post_id)

    if BillBored.Geo.within?(post_location, user_location, radius) and
         subscribed_post_type?(incoming_post_type, assigned_post_types) and
         friend_or_following?(author_id, user_id) do
      push(socket, "post:update", payload)
    end

    {:noreply, socket}
  end

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

  defp find_author(post_id) do
    post = Repo.get(Post, post_id)
    post.author_id
  end

  defp friend_or_following?(author_id, user_id) do
    friends_ids = Users.list_friend_ids(user_id)
    followings_ids = Users.user_followings_ids(user_id)
    author_id in (friends_ids ++ followings_ids)
  end

  defp subscribed_post_type?(incoming_post_type, assigned_post_types) do
    incoming_post_type in assigned_post_types
  end

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
