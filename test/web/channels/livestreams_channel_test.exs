defmodule Web.LivestreamsChannelTest do
  use Web.ChannelCase, async: true
  alias BillBored.{User, Livestream}

  describe "query" do
    setup [:create_livestreams, :connect, :join]

    test "location point", %{socket: socket, livestreams: livestreams} do
      ref =
        push(socket, "livestreams:list", %{
          "geometry" => %{"type" => "Point", "coordinates" => [40.5, -50.0]}
        })

      assert_reply(ref, :ok, %{"livestreams" => received_livestreams})

      assert Enum.sort_by(received_livestreams, fn livestream -> livestream["id"] end) ==
               livestreams
               |> Enum.sort_by(fn livestream -> livestream.id end)
               |> Phoenix.View.render_many(Web.LivestreamView, "livestream.json")
    end

    test "location point for blocked user", %{socket: socket, livestreams: [l1 | livestreams]} do
      %{assigns: %{user: user}} = socket
      insert(:user_block, blocker: l1.owner, blocked: user)

      ref =
        push(socket, "livestreams:list", %{
          "geometry" => %{"type" => "Point", "coordinates" => [40.5, -50.0]}
        })

      assert_reply(ref, :ok, %{"livestreams" => received_livestreams})

      assert Enum.sort_by(received_livestreams, fn livestream -> livestream["id"] end) ==
               livestreams
               |> Enum.sort_by(fn livestream -> livestream.id end)
               |> Phoenix.View.render_many(Web.LivestreamView, "livestream.json")
    end

    @tag :skip
    test "location polygon", %{socket: socket, livestreams: livestreams} do
      ref =
        push(socket, "livestreams:list", %{
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

      assert_reply(ref, :ok, %{"livestreams" => received_livestreams})

      received_livestreams =
        Enum.sort_by(received_livestreams, fn livestream -> livestream["id"] end)

      assert received_livestreams ==
               Phoenix.View.render_many(livestreams, Web.LivestreamView, "livestream.json")
    end

    @tag :skip
    test "location polygon for blocked user", %{socket: socket, livestreams: [l1 | livestreams]} do
      %{assigns: %{user: user}} = socket
      insert(:user_block, blocker: l1.owner, blocked: user)

      ref =
        push(socket, "livestreams:list", %{
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

      assert_reply(ref, :ok, %{"livestreams" => received_livestreams})

      received_livestreams =
        Enum.sort_by(received_livestreams, fn livestream -> livestream["id"] end)

      assert received_livestreams ==
               Phoenix.View.render_many(livestreams, Web.LivestreamView, "livestream.json")
    end
  end

  describe "push" do
    setup [:connect]

    @tag :skip
    test "when livestream comes from within channel range", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "livestreams", join_params({30.0, 30.0}))

      # creates a livestream which then will be broadcasted
      %Livestream{id: livestream_id, title: title} =
        insert(:livestream, location: point({30.0, 30.0}), active?: false)

      # publishes a livestream (called from nginx_controller)
      BillBored.Livestreams.InMemory.publish(livestream_id)

      assert_push("livestream:new", sent_livestream)

      assert %{
               "id" => ^livestream_id,
               "title" => ^title,
               "coordinates" => %{"latitude" => 30.0, "longitude" => 30.0},
               "active?" => true,
               "recorded?" => false
             } = sent_livestream

      # finishes the livestream
      BillBored.Livestreams.InMemory.publish_done(livestream_id)

      assert_push("livestream:over", %{"id" => ^livestream_id})
    end

    @tag :skip
    test "when livestream comes from outside channel range", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "livestreams", join_params({30.0, 30.0}))

      # creates a livestream which then will be broadcasted
      %Livestream{id: livestream_id} =
        insert(:livestream, location: point({50.0, 50.0}), active?: false)

      # publishes a livestream (called from nginx_controller)
      BillBored.Livestreams.InMemory.publish(livestream_id)

      refute_push("livestream:new", %{"id" => ^livestream_id})
    end
  end

  defp connect(_context) do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})
    {:ok, %{user: user, socket: socket}}
  end

  defp join(%{socket: socket}) do
    {:ok, _reply, socket} = subscribe_and_join(socket, "livestreams", join_params())
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), socket.channel_pid)
    {:ok, %{socket: socket}}
  end

  defp create_livestreams(_context) do
    # inserts a few livestreams to search through
    %Livestream{} = l1 = insert(:livestream, location: point({40.5, -50.0}), active?: true)

    %Livestream{} = l2 = insert(:livestream, location: point({40.5001, -50.0001}), active?: true)

    # shouldn't be found (too far)
    %Livestream{} = l3 = insert(:livestream, location: point({0, 0}), active?: true)

    # not active, shouldn't be found either
    %Livestream{} = insert(:livestream, location: point({40.5001, -50.0001}), active?: false)

    # >24h into the past
    %Livestream{} =
      insert(
        :livestream,
        location: point({40.51, -50.0}),
        created: into_past(DateTime.utc_now(), 30),
        active?: false
      )

    # inserts a few comments into some livestreams
    insert(:livestream_comment, livestream: l2, body: "oh damn")
    insert(:livestream_comment, livestream: l2, body: "oh damn2")
    insert(:livestream_comment, livestream: l2, body: "oh damn3")

    insert(:livestream_comment, livestream: l3, body: "oh damn not found")
    insert(:livestream_comment, livestream: l3, body: "oh damn2 not found")

    {:ok, %{livestreams: [l1, l2]}}
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
