defmodule Web.OffersChannelTest do
  use Web.ChannelCase, async: true
  alias BillBored.User

  describe "join" do
    setup [:connect]

    test "with valid params assigns params to socket ", %{socket: socket} do
      geo = %{"type" => "Point", "coordinates" => [30.700873561540504, 76.788390984195786]}
      params = %{"radius" => 5819.68555, "geometry" => geo}

      {:ok, _reply, updated_socket} = subscribe_and_join(socket, "offers", params)

      refute Map.has_key?(socket.assigns, :location)

      assert updated_socket.assigns.radius == 5819.68555
      assert updated_socket.assigns.location == %BillBored.Geo.Point{
        lat: 30.700873561540504,
        long: 76.78839098419579
      }
    end

    test "with invalid params raises error", %{socket: socket} do
      assert {:error,
              %{"details" => "invalid params, need geometry(point) and radius"}} ==
               subscribe_and_join(socket, "offers", %{})
    end
  end

  describe "update" do
    setup [:connect, :join]

    test "raises no error", %{socket: socket} do
      geo = %{"type" => "Point", "coordinates" => [30.700873561540504, 76.788390984195786]}

      params = %{
        "radius" => 5819.68555,
        "geometry" => geo
      }

      ref = push(socket, "update", params)

      assert_reply(ref, :ok, %{})
    end
  end

  describe "markers event" do
    setup(context) do
      location = %BillBored.Geo.Point{lat: 51.13606981407861, long: -0.17065179253916085}
      radius = 8000

      p1 = insert(:business_post, location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037})

      # "event" type posts are ignored
      insert(:post, business: build(:business_account), type: "event", location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037})

      # non-business posts are ignored
      insert(:post, location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037})

      p2 = insert(:business_post, inserted_at: Timex.shift(Timex.now, days: -30), location: %BillBored.Geo.Point{lat: 51.188059, long: -0.139366})

      {:ok, context} = connect(context)
      Map.merge(context, %{location: location, radius: radius, posts: [p1, p2]})
    end

    test "markers are pushed after join", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket,
      posts: [%{id: p1_id}, %{id: p2_id}]
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      assert_push("markers", %{markers: [m1]})

      assert %{
        location: %{
          coordinates: [51.180066, -0.1517015]
        },
        location_geohash: "gcpght193pg1",
        precision: 5,
        posts_count: 2,
        top_posts: top_posts
      } = m1

      assert [%{id: ^p1_id}, %{id: ^p2_id}] = top_posts
    end

    test "markers are pushed after location is updated", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      assert_push("markers", %{markers: [_m1]})

      business = insert(:business_account)
      %{id: post_id} = post = insert(:post, type: "offer", business_id: business.id)

      ref = push(socket, "update", %{
        "radius" => 1000,
        "geometry" => %{"type" => "Point", "coordinates" => [post.location.lat, post.location.long]}
      })
      assert_reply(ref, :ok, %{})

      assert_push("markers", %{markers: [m1]})

      assert %{
        location: %{
          coordinates: [50.0, 50.0]
        },
        location_geohash: "v0gs3y0zh7w1",
        precision: 6,
        posts_count: 1,
        top_posts: [
          %{id: ^post_id}
        ]
      } = m1
    end
  end

  describe "post:new" do
    setup(context) do
      {:ok, context} = connect(context)

      Map.merge(context, %{
        location: %BillBored.Geo.Point{lat: 51.13606981407861, long: -0.17065179253916085},
        radius: 8000
      })
    end

    test "sends notification about new post within range", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat} = location,
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      post = insert(:post, type: "offer", location: location, business_id: insert(:business_account).id)

      message = %{
        location: post.location,
        payload: %{"post" => %{"id" => post.id}},
        post_type: String.to_atom(post.type),
        author: post.author
      }

      Web.Endpoint.broadcast("offers", "post:new", message)

      assert_push("post:new", _payload)
    end

    test "does not send notification for post outside range", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      post = insert(:post, location: %BillBored.Geo.Point{long: 0, lat: 0}, business_id: insert(:business_account).id)

      message = %{
        location: post.location,
        payload: %{"post" => %{"id" => post.id}},
        post_type: String.to_atom(post.type),
        author: post.author
      }

      Web.Endpoint.broadcast("offers", "post:new", message)

      refute_push("post:new", _payload)
    end

    test "does not send notification for post of unexpected type", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat} = location,
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      post = insert(:post, type: "poll", location: location, business_id: insert(:business_account).id)

      message = %{
        location: post.location,
        payload: %{"post" => %{"id" => post.id}},
        post_type: String.to_atom(post.type),
        author: post.author
      }

      Web.Endpoint.broadcast("offers", "post:new", message)

      refute_push("post:new", _payload)
    end
  end

  describe "post:update" do
    setup(context) do
      {:ok, context} = connect(context)

      Map.merge(context, %{
        location: %BillBored.Geo.Point{lat: 51.13606981407861, long: -0.17065179253916085},
        radius: 8000
      })
    end

    test "sends notification about new post within range", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat} = location,
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      post = insert(:post, type: "offer", location: location, business_id: insert(:business_account).id)

      message = %{
        location: post.location,
        post_type: String.to_atom(post.type),
        author: post.author,
        payload: %{
          "id" => post.id,
          "changes" => %{"body" => post.body}
        }
      }

      Web.Endpoint.broadcast("offers", "post:update", message)

      assert_push("post:update", _payload)
    end

    test "does not send notification for post outside range", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      post = insert(:post, type: "offer", location: %BillBored.Geo.Point{long: 0, lat: 0}, business_id: insert(:business_account).id)

      message = %{
        location: post.location,
        post_type: String.to_atom(post.type),
        author: post.author,
        payload: %{
          "id" => post.id,
          "changes" => %{"body" => post.body}
        }
      }

      Web.Endpoint.broadcast("offers", "post:update", message)

      refute_push("post:update", _payload)
    end

    test "does not send notification for post of unexpected type", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat} = location,
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      post = insert(:post, type: "poll", location: location, business_id: insert(:business_account).id)

      message = %{
        location: post.location,
        post_type: String.to_atom(post.type),
        author: post.author,
        payload: %{
          "id" => post.id,
          "changes" => %{"body" => post.body}
        }
      }

      Web.Endpoint.broadcast("offers", "post:update", message)

      refute_push("post:update", _payload)
    end
  end

  describe "post:delete" do
    setup(context) do
      {:ok, context} = connect(context)

      Map.merge(context, %{
        location: %BillBored.Geo.Point{lat: 51.13606981407861, long: -0.17065179253916085},
        radius: 8000
      })
    end

    test "sends notification about new post within range", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat} = location,
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      message = %{
        location: location,
        post_type: :offer,
        author: insert(:user),
        payload: %{"id" => 123}
      }

      Web.Endpoint.broadcast("offers", "post:delete", message)

      assert_push("post:delete", _payload)
    end

    test "does not send notification for post outside range", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      message = %{
        location: %BillBored.Geo.Point{long: 0, lat: 0},
        post_type: :offer,
        author: insert(:user),
        payload: %{"id" => 123}
      }

      Web.Endpoint.broadcast("offers", "post:delete", message)

      refute_push("post:delete", _payload)
    end

    test "does not send notification for post of unexpected type", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat} = location,
      radius: radius,
      socket: socket
    } do
      {:ok, _reply, _socket} = subscribe_and_join(socket, "offers", join_params({lat, lon}, radius))

      message = %{
        location: location,
        post_type: :poll,
        author: insert(:user),
        payload: %{"id" => 123}
      }

      Web.Endpoint.broadcast("offers", "post:delete", message)

      refute_push("post:delete", _payload)
    end
  end

  defp connect(_context) do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})
    {:ok, %{user: user, socket: socket}}
  end

  defp join(%{socket: socket}) do
    {:ok, _reply, socket} = subscribe_and_join(socket, "offers", join_params())
    {:ok, %{socket: socket}}
  end

  defp join_params(coordinates \\ {0, 0}, radius \\ 1000) do
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
end
