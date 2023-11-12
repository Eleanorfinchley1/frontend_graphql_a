defmodule Web.DropchatsChannelTest do
  use Web.ChannelCase, async: true
  alias BillBored.User

  describe "query" do
    setup [:create_dropchats, :connect, :join]

    test "location point", %{socket: socket, dropchats: dropchats, user: user} do
      ref =
        push(socket, "dropchats:list", %{
          "geometry" => %{"type" => "Point", "coordinates" => [40.5, -50.0]}
        })

      key = "#{user.id}"
      # assert_reply(ref, :ok, %{^key => received_dropchats})
      :timer.sleep(1000)

      assert_received %Phoenix.Socket.Message{
        event: "dropchats:list_per_user",
        payload: %{^key => received_dropchats},
        topic: "dropchats"
      }

      received_dropchats = Enum.sort_by(received_dropchats, fn dropchat -> dropchat["id"] end)

      assert received_dropchats == []
    end

    test "location polygon", %{socket: socket, dropchats: dropchats, user: user} do
      ref =
        push(socket, "dropchats:list", %{
          "geometry" => %{
            "type" => "Polygon",
            "coordinates" => [
              [
                [40.0, -49.0],
                [40.0, -55.0],
                [50.7, -55.0],
                [50.7, -49.0],
                [40.0, -49.0]
              ]
            ]
          }
        })

      key = "#{user.id}"

      # assert_push("dropchats:list_per_user", %{^key => received_dropchats})
      :timer.sleep(1000)

      assert_received %Phoenix.Socket.Message{
        event: "dropchats:list_per_user",
        payload: %{^key => received_dropchats},
        topic: "dropchats"
      }
      # assert_reply(ref, :ok, %{^key => received_dropchats})

      received_dropchats = Enum.sort_by(received_dropchats, fn dropchat -> dropchat["id"] end)

      assert received_dropchats == []
    end
  end

  describe "push" do
    setup [:connect]

    import Plug.Conn
    import Phoenix.ConnTest, except: [connect: 2]
    alias Web.Router.Helpers, as: Routes

    test "when dropchat comes from within range", %{socket: socket} do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "dropchats", join_params({30.0, 30.0}))

      # creates a dropchat which then will be broadcasted
      conn = Phoenix.ConnTest.build_conn()

      assert %{
               "chat_type" => "dropchat",
               "id" => chat_id,
               "location" => %{
                 "coordinates" => [30.0, 30.0],
                 "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                 "type" => "Point"
               },
               "place" => nil,
               "private" => false,
               "reach_area_radius" => 2.0
             } =
               conn
               |> put_req_header("authorization", "Bearer #{insert(:auth_token).key}")
               |> post(Routes.chat_path(conn, :create), %{
                 "title" => "some dropchat",
                 "location" => %{"coordinates" => [30.0, 30.0]},
                 "reach_area_radius" => 2.0,
                 "fake_location?" => false
               })
               |> json_response(200)

      assert_push("dropchat:new", %{"dropchat" => sent_dropchat})

      assert %{"id" => ^chat_id, "title" => "some dropchat"} = sent_dropchat
      # assert sent_dropchat["place"].name == dropchat.place.name
      # assert sent_dropchat["place"].vicinity == dropchat.place.vicinity
    end

    test "when dropchat comes from outside of range", %{socket: socket} do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "dropchats", join_params({30.0, 30.0}))

      # creates a dropchat which then will be broadcasted
      conn = Phoenix.ConnTest.build_conn()

      assert %{
               "chat_type" => "dropchat",
               "id" => chat_id,
               "location" => %{
                 "coordinates" => [50.0, 50.0],
                 "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                 "type" => "Point"
               },
               "place" => nil,
               "private" => false,
               "reach_area_radius" => 2.0
             } =
               conn
               |> put_req_header("authorization", "Bearer #{insert(:auth_token).key}")
               |> post(Routes.chat_path(conn, :create), %{
                 "title" => "some dropchat",
                 "location" => %{"coordinates" => [50.0, 50.0]},
                 "reach_area_radius" => 2.0,
                 "fake_location?" => false
               })
               |> json_response(200)

      refute_push("dropchat:new", %{"dropchat" => %{"id" => ^chat_id}})
    end
  end

  defp connect(_context) do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})
    {:ok, %{user: user, socket: socket}}
  end

  defp join(%{socket: socket}) do
    {:ok, _reply, socket} = subscribe_and_join(socket, "dropchats", join_params())
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), socket.channel_pid)
    {:ok, %{socket: socket}}
  end

  defp create_dropchats(_context) do
    place1 = insert(:place, location: point({40.5, -50.0}))
    place2 = insert(:place, location: point({40.5001, -50.0001}))

    # inserts a few dropchats to search through
    d1 =
      insert(
        :chat_room,
        location: point({40.5, -50.0}),
        private: false,
        place: place1,
        reach_area_radius: 2.0
      )

    d2 =
      insert(
        :chat_room,
        location: point({40.5001, -50.0001}),
        private: false,
        place: place2,
        reach_area_radius: 3.0
      )

    # shouldn't be found (too far)
    d3 =
      insert(
        :chat_room,
        location: point({0, 0}),
        private: false,
        place: insert(:place, location: point({0, 0}))
      )

    # private, shouldn't be found either
    _d =
      insert(
        :chat_room,
        location: point({40.5001, -50.0001}),
        private: true,
        place: insert(:place, location: point({40.5001, -50.0001}))
      )

    # >24h into the past
    _d =
      insert(
        :chat_room,
        location: point({40.51, -50.0}),
        created: into_past(DateTime.utc_now(), 30),
        last_interaction: into_past(DateTime.utc_now(), 30),
        private: false,
        place: insert(:place, location: point({40.51, -50.0}))
      )

    # inserts a few messages into some dropchats
    insert(:chat_message, room: d2, message: "oh damn")
    insert(:chat_message, room: d2, message: "oh damn2")
    insert(:chat_message, room: d2, message: "oh damn3")

    insert(:chat_message, room: d3, message: "oh damn not found")
    insert(:chat_message, room: d3, message: "oh damn2 not found")

    # updates the dropchats with their messages count
    d1 = %{d1 | messages_count: 0}
    d2 = %{d2 | messages_count: 3}

    {:ok, %{dropchats: Repo.preload([d1, d2], place: :types)}}
  end

  defp join_params(coordinates \\ {40.5, -50}, radius \\ 1000) do
    %BillBored.Geo.Point{lat: lat, long: long} = point(coordinates)
    # simulating the client sending the coords in flipped order (lat, long)
    # instead of the correct (long, lat)
    geometry = Geo.JSON.encode!(%Geo.Point{coordinates: {lat, long}})

    %{
      "radius" => radius,
      "geometry" => geometry
    }
  end

  defp point({lat, long}) do
    %BillBored.Geo.Point{lat: lat, long: long}
  end

  @spec into_past(DateTime.t(), pos_integer) :: DateTime.t()
  defp into_past(dt, hours) do
    DateTime.from_unix!(DateTime.to_unix(dt) - hours * 60 * 60)
  end
end
