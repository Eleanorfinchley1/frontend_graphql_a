defmodule Web.AreaNotificationChannel do
  use Web, :channel
  use Web.Channels.ChannelTasks

  import BillBored.ServiceRegistry, only: [service: 1]
  require Logger

  alias BillBored.Notifications.AreaNotifications
  alias BillBored.Notifications.AreaNotifications.MatchData
  alias BillBored.Notifications.AreaNotification

  @geohash_precision 4
  @count_receivers_timeout 30_000

  @impl true
  def join(
        "area_notifications:lobby",
        %{"geometry" => %{"type" => "Point"} = geometry},
        %{assigns: %{user: %{id: user_id}}} = socket
      ) do
    with {:ok, location} <- parse_location(geometry) do
      send(self(), :location_updated)

      new_socket =
        socket
        |> assign(:location, location)
        |> assign(:geohash, nil)
        |> assign(:user_match_data, MatchData.new(BillBored.Users.get!(user_id)))

      {:ok, new_socket}
    else
      error ->
        {:error,
         %{
           "reason" => "invalid_params",
           "details" => "failed to parse location: #{inspect(error)}"
         }}
    end
  end

  def join(
        "area_notifications:" <> geohash,
        %{"geometry" => %{"type" => "Point"} = geometry},
        %{assigns: %{user: %{id: user_id}}} = socket
      ) do
    with {:ok, %{long: lon, lat: lat} = location} <- parse_location(geometry),
         true <- geohash == Geohash.encode(lat, lon, @geohash_precision) do
      new_socket =
        socket
        |> assign(:location, location)
        |> assign(:geohash, geohash)
        |> assign(:user_match_data, MatchData.new(BillBored.Users.get!(user_id)))
        |> run_exclusive_task("notifications:fetch", {user_id, location})
        |> run_exclusive_task("notifications:scheduled:fetch", {user_id})

      {:ok, new_socket}
    else
      false ->
        {:error,
         %{
           "reason" => "invalid_params",
           "details" => "location does not match geohash #{geohash}"
         }}

      error ->
        {:error,
         %{
           "reason" => "invalid_params",
           "details" => "failed to parse location: #{inspect(error)}"
         }}
    end
  end

  def join(
        "area_notifications:" <> _,
        _params,
        _socket
      ) do
    {:error, %{"reason" => "invalid_params", "details" => "'geometry' of Point type is expected"}}
  end

  @impl true
  def start_task("notifications:fetch", {user_id, location}, socket) do
    task =
      Task.async(fn ->
        case service(AreaNotifications).find_matching(user_id, location) do
          nil ->
            nil

          %AreaNotification{} = notification ->
            rendered_notification =
              Phoenix.View.render_one(notification, Web.AreaNotificationView, "show.json")

            match_data = AreaNotifications.MatchData.new(notification)

            %{
              notification: notification,
              rendered_notification: rendered_notification,
              match_data: match_data
            }
        end
      end)

    {:ok, task, socket}
  end

  def start_task("notifications:scheduled:fetch", {user_id}, socket) do
    task =
      Task.async(fn ->
        notifications = service(AreaNotifications).get_scheduled(user_id)

        rendered_notifications =
          Phoenix.View.render_many(notifications, Web.AreaNotificationView, "show.json")

        %{
          notifications: notifications,
          rendered_notifications: rendered_notifications
        }
      end)

    {:ok, task, socket}
  end

  @impl true
  def handle_task(
        "notifications:fetch",
        :completed,
        %{
          notification: %{radius: radius, location: notification_location} = notification,
          rendered_notification: rendered_notification,
          match_data: match_data
        },
        %{
          assigns: %{
            user: %{id: user_id},
            location: user_location,
            user_match_data: user_match_data
          }
        } = socket
      ) do
    if BillBored.Geo.within?(notification_location, user_location, radius) and
         MatchData.matches?(match_data, user_match_data) do
      AreaNotifications.add_receivers(notification, [user_id])
      AreaNotifications.update_receivers_count(notification)
      push(socket, "notification:broadcast", rendered_notification)
    end

    {:noreply, socket}
  end

  def handle_task(
        "notifications:scheduled:fetch",
        :completed,
        %{
          rendered_notifications: rendered_notifications
        },
        socket
      ) do
    if length(rendered_notifications) > 0 do
      push(socket, "notification:scheduled", %{area_notifications: rendered_notifications})
    end

    {:noreply, socket}
  end

  def handle_task(_, :completed, _, socket) do
    {:noreply, socket}
  end

  def handle_task(_, :cancelled, _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_in(
        "location:update",
        %{"geometry" => %{"type" => "Point"} = geometry},
        socket
      ) do
    with {:ok, location} <- parse_location(geometry) do
      new_socket = assign(socket, :location, location)
      send(self(), :location_updated)
      {:reply, :ok, new_socket}
    else
      error ->
        {:reply,
         {:error,
          %{
            "reason" => "invalid_param",
            "details" => "failed to parse location: #{inspect(error)}"
          }}, socket}
    end
  end

  def handle_in("location:update", _params, _socket) do
    {:error, %{"reason" => "invalid_params", "details" => "'geometry' of Point type is expected"}}
  end

  @impl true
  def handle_info(:location_updated, %{assigns: %{user: user, location: location}} = socket) do
    with {:ok, user_location} <- BillBored.Clickhouse.UserLocation.build(user, location) do
      service(BillBored.Clickhouse.UserLocations).create(user_location)
    end

    {:noreply, maybe_change_area(socket)}
  end

  def handle_info(msg, socket) do
    handle_info_tasks(msg, socket)
  end

  intercept(["notification:broadcast"])

  @impl true
  def handle_out(
        "notification:broadcast",
        %{
          notification: %{id: id, radius: radius, location: notification_location},
          rendered_notification: rendered_notification,
          match_data: match_data
        },
        %{
          assigns: %{
            user: %{id: user_id},
            location: user_location,
            user_match_data: user_match_data
          }
        } = socket
      ) do
    if BillBored.Geo.within?(notification_location, user_location, radius) and
         MatchData.matches?(match_data, user_match_data) do
      push(socket, "notification:broadcast", rendered_notification)

      Phoenix.PubSub.broadcast(
        Web.PubSub,
        "area_notifications:#{id}",
        {:pushed_to, %{user_id: user_id}}
      )
    end

    {:noreply, socket}
  end

  def handle_out("notification:broadcast", _msg, socket) do
    {:noreply, socket}
  end

  def notify(
        %AreaNotification{id: id, location: location, radius: radius} = notification,
        match_data
      ) do
    rendered_notification =
      Phoenix.View.render_one(notification, Web.AreaNotificationView, "show.json")

    # TODO: Use global GenServer
    task =
      Task.Supervisor.async_nolink(BillBored.TaskSupervisor, fn ->
        Phoenix.PubSub.subscribe(Web.PubSub, "area_notifications:#{id}")

        Logger.debug(
          "Broadcasting area notification at #{inspect(location)} over #{radius}m using match data #{
            inspect(match_data)
          }: #{inspect(notification)}"
        )

        geohashes = BillBored.Geo.Hash.all_within(location, radius, @geohash_precision)

        Enum.each(geohashes, fn geohash ->
          Web.Endpoint.broadcast("area_notifications:#{geohash}", "notification:broadcast", %{
            notification: notification,
            match_data: match_data,
            rendered_notification: rendered_notification
          })
        end)

        count_receivers(notification, [], 0)
      end)

    task
  end

  defp count_receivers(notification, user_ids, count) do
    receive do
      {:pushed_to, %{user_id: user_id}} ->
        if count >= 999 do
          AreaNotifications.add_receivers(notification, [user_id | user_ids])
          AreaNotifications.update_receivers_count(notification)
          count_receivers(notification, [], 0)
        else
          count_receivers(notification, [user_id | user_ids], count + 1)
        end
    after
      @count_receivers_timeout ->
        AreaNotifications.add_receivers(notification, user_ids)
        AreaNotifications.update_receivers_count(notification)
    end
  end

  defp parse_location(geometry) do
    with {:ok, %Geo.Point{coordinates: {lat, long}}} <- Geo.JSON.decode(geometry) do
      {:ok, %BillBored.Geo.Point{lat: lat, long: long}}
    end
  end

  defp maybe_change_area(
         %{
           assigns: %{
             geohash: current_geohash,
             location: %BillBored.Geo.Point{long: lon, lat: lat} = point
           }
         } = socket
       ) do
    location_geohash = Geohash.encode(lat, lon, @geohash_precision)

    if location_geohash != current_geohash do
      push(socket, "area:change", %{
        area: %{
          location: Phoenix.View.render_one(point, Web.LocationView, "show.json"),
          location_geohash: location_geohash,
          notifications_channel: "area_notifications:#{location_geohash}"
        }
      })

      assign(socket, :geohash, location_geohash)
    else
      socket
    end
  end
end
