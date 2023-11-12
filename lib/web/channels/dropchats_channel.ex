defmodule Web.DropchatsChannel do
  use Web, :channel

  # TODO try catch
  def join(
        "dropchats",
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

  def join("dropchats", _params, _socket) do
    {:error, %{"details" => "invalid params, need geometry(point) and radius"}}
  end

  def handle_in(
        "dropchats:list",
        %{"geometry" => geometry} = params,
        %Phoenix.Socket{
          assigns: %{
            location: %BillBored.Geo.Point{lat: lat, long: long} = _user_location,
            user: %BillBored.User{id: user_id, university_id: university_id} = _user
          }
        } = socket
      ) do
    radius = params["radius"] || socket.assigns.radius

    locations = Signer.Config.get(:user_locations) || %{}
    locations = Map.put(locations, "#{user_id}", %{
      user_id: user_id,
      university_id: university_id,
      lat: lat,
      long: long,
      geometry: geometry,
      radius: radius,
      keyword: params["keyword"]
    })

    Signer.Config.put(:user_locations, locations)

    Web.Endpoint.broadcast(
      "dropchats",
      "dropchats:send_sorted_list",
      %{
        "#{user_id}" => %{
          user_id: user_id,
          university_id: university_id,
          lat: lat,
          long: long,
          geometry: geometry,
          radius: radius,
          keyword: params["keyword"]
        }
      }
    )

    {:noreply, socket}
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

  # TODO test
  def handle_in("dropchats:statistics", %{"dropchat_ids" => dropchat_ids}, socket) do
    statistics = BillBored.Chat.Rooms.get_dropchat_statistics(dropchat_ids)
    {:reply, {:ok, %{"statistics" => statistics}}, socket}
  end

  # TODO very naive approach, optimize
  intercept([
    "dropchat:new",
    "dropchats:send_sorted_list"
  ])

  def handle_out(
        "dropchat:new",
        %{
          location: %BillBored.Geo.Point{} = dropchat_location,
          dropchat_reach_area_radius: dropchat_reach_area_radius,
          payload: payload
        },
        %Phoenix.Socket{
          assigns: %{location: %BillBored.Geo.Point{} = user_location, radius: radius}
        } = socket
      ) do
    if BillBored.Geo.within?(dropchat_location, user_location, radius) do
      # TODO refactor
      payload =
        Map.put(
          payload,
          "is_access_required",
          access_required?(user_location, dropchat_location, dropchat_reach_area_radius)
        )

      push(socket, "dropchat:new", payload)
    end

    {:noreply, socket}
  end

  def handle_out(
    "dropchats:send_sorted_list",
    user_locations,
    socket
  ) do
    user_dropchats = Map.keys(user_locations)
    |> Enum.reduce(%{}, fn key, user_dropchats ->
      location = Map.get(user_locations, key, nil)

      if not is_nil(location) do
        rendered_dropchats =
          location.geometry
          |> Geo.JSON.decode!()
          |> case do
            # TODO
            %Geo.Point{coordinates: {lat, long}} ->
              radius = location.radius
              sort_by_recent_chat = BillBored.Users.users_count < 1000

              if sort_by_recent_chat do
                BillBored.Chat.Rooms.list_location_dropchats_sorted_by_updated(
                  location,
                  %BillBored.Geo.Point{lat: lat, long: long},
                  radius
                )
              else
                BillBored.Chat.Rooms.list_user_sort_dropchats_by_location(
                  location,
                  %BillBored.Geo.Point{lat: lat, long: long},
                  radius
                )
              end

            # TODO
            %Geo.Polygon{coordinates: coords} ->
              sort_by_recent_chat = BillBored.Users.users_count < 1000
              polygon = %BillBored.Geo.Polygon{
                # TODO
                coords:
                  Enum.flat_map(coords, fn line ->
                    Enum.map(line, fn {lat, long} ->
                      %BillBored.Geo.Point{lat: lat, long: long}
                    end)
                  end)
              }

              if sort_by_recent_chat do
                BillBored.Chat.Rooms.list_location_dropchats_sorted_by_updated(location, polygon)
              else
                BillBored.Chat.Rooms.list_user_sort_dropchats_by_location(location, polygon)
              end
          end
          |> Enum.map(fn %BillBored.Chat.Room{
                          location: dropchat_location,
                          reach_area_radius: reach_area_radius
                        } = dropchat ->
            if Decimal.decimal?(reach_area_radius) do
              %{
                dropchat
                | is_access_required:
                    access_required?(
                      %BillBored.Geo.Point{lat: location.lat, long: location.long},
                      dropchat_location,
                      Decimal.to_float(reach_area_radius) * 1000
                    )
              }
            else
              dropchat
            end
          end)
          |> Repo.preload(place: [:types])
          |> Phoenix.View.render_many(Web.RoomView, "dropchat.json")

        Map.put(user_dropchats, key, rendered_dropchats)
      end
    end)

    push(socket, "dropchats:list_per_user", user_dropchats)

    {:noreply, socket}
  end

  def terminate(_reason, %{assigns: %{user: %BillBored.User{id: user_id} = _user}} = _socket) do

    locations = Signer.Config.get(:user_locations) || %{}
    locations = Map.delete(locations, "#{user_id}")
    Signer.Config.put(:user_locations, locations)

    :ok
  end

  defp access_required?(user_location, dropchat_location, dropchat_reach_area_radius) do
    not BillBored.Geo.within?(user_location, dropchat_location, dropchat_reach_area_radius)
  end
end
