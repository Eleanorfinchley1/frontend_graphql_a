defmodule Web.PostChannelTest do
  use Web.ChannelCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias BillBored.User

  setup_all do
    HTTPoison.start()
  end

  describe "join" do
    setup [:connect]

    test "with valid params updates socket assigns", %{socket: socket} do
      geo = %{"type" => "Point", "coordinates" => [30.700873561540504, 76.788390984195786]}

      params = %{
        "radius" => 5819.68555,
        "geometry" => geo,
        "post_types" => ["regular"]
      }

      {:ok, _reply, updated_socket} = subscribe_and_join(socket, "posts", params)

      refute Map.has_key?(socket.assigns, :location)

      assert updated_socket.assigns.location == %BillBored.Geo.Point{
               lat: 30.700873561540504,
               long: 76.78839098419579
             }

      assert updated_socket.assigns.radius == 5819.68555
      assert updated_socket.assigns.post_types == [:regular]
    end

    test "with invalid params raises error", %{socket: socket} do
      assert {:error,
              %{"details" => "invalid params, need geometry(point), radius, and post_types"}} ==
               subscribe_and_join(socket, "posts", %{})
    end
  end

  describe "update" do
    setup [:connect, :join]

    test "raises no error", %{socket: socket} do
      geo = %{"type" => "Point", "coordinates" => [30.700873561540504, 76.788390984195786]}

      params = %{
        "radius" => 5819.68555,
        "geometry" => geo,
        "post_types" => ["regular"]
      }

      ref = push(socket, "update", params)
      assert_reply(ref, :ok, %{})
    end
  end

  describe "events query" do
    setup [:create_event_posts, :connect, :join]

    @tag :skip
    test "location point", %{socket: socket, event_posts: event_posts} do
      ref =
        push(socket, "posts:list", %{
          "geometry" => %{"type" => "Point", "coordinates" => [40.5, -50.0]}
        })

      assert_reply(ref, :ok, %{posts: received_posts})

      received_posts = Enum.map(received_posts, &add_statistics/1)

      assert length(received_posts) ==
               length(
                 Phoenix.View.render_many(event_posts, Web.PostView, "show.json", %{
                   user_id: socket.assigns.user.id
                 })
               )
    end

    @tag :skip
    test "location polygon", %{socket: socket, events: events} do
      ref =
        push(socket, "posts:list", %{
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

      assert_reply(ref, :ok, %{posts: received_posts})

      received_posts = Enum.map(received_posts, &add_statistics/1)

      assert length(received_posts) ==
               length(
                 Phoenix.View.render_many(events, Web.PostView, "show.json", %{
                   user_id: socket.assigns.user.id
                 })
               )
    end
  end

  describe "posts query" do
    setup [:create_event_posts, :connect, :join]

    test "location point", %{socket: socket, event_posts: posts} do
      ref =
        push(socket, "posts:list", %{
          "geometry" => %{"type" => "Point", "coordinates" => [40.5, -50.0]}
        })

      assert_reply(ref, :ok, %{posts: received_posts})

      assert received_posts |> Enum.map(& &1.id) |> Enum.sort() ==
               posts
               |> Enum.map(& &1.id)
               |> Enum.sort()
    end

    @tag :skip
    test "location polygon", %{socket: socket, posts: posts} do
      ref =
        push(socket, "posts:list", %{
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

      assert_reply(ref, :ok, %{posts: received_posts})

      received_posts = Enum.map(received_posts, &add_statistics/1)

      assert received_posts ==
               Phoenix.View.render_many(posts, Web.PostView, "show.json", %{
                 user_id: socket.assigns.user.id
               })
    end
  end

  @tag :skip
  describe "posts:list:eventful" do
    import Ecto.Query
    setup [:connect, :join_with_regular_post_type]

    test "eventful posts are streamed after a posts:list request (single page and api request)",
         %{socket: socket} do
      use_cassette "post_channel_eventful_moscow" do
        push(socket, "posts:list", %{
          "geometry" => %{"type" => "Point", "coordinates" => [55.7558, 37.6173]}
        })

        assert_push "posts:list:eventful", push, 1000
        assert %{posts: posts} = push
        assert length(posts) == 10
      end

      assert 10 ==
               BillBored.Post
               |> where([p], not is_nil(p.eventful_id))
               |> select([p], count(p.id))
               |> Repo.one()
    end

    test "eventful posts are streamed after a posts:list request (multiple pages and api requests)",
         %{socket: socket} do
      use_cassette "post_channel_eventful_berlin", match_requests_on: [:query] do
        push(socket, "posts:list", %{
          "geometry" => %{"type" => "Point", "coordinates" => [52.5200, 13.4050]}
        })

        # first page
        assert_push "posts:list:eventful", push, 1000
        assert %{posts: posts} = push
        assert length(posts) == 10

        # pages 2 through 3
        Enum.each(2..3, fn _ ->
          assert_push "posts:list:eventful", %{posts: _posts}, 1000
        end)
      end

      assert 25 ==
               BillBored.Post
               |> where([p], not is_nil(p.eventful_id))
               |> select([p], count(p.id))
               |> Repo.one()
    end
  end

  describe "push" do
    setup [:connect]

    import Plug.Conn
    import Phoenix.ConnTest, except: [connect: 2]
    alias Web.Router.Helpers, as: Routes

    test "when post comes from within range", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      # creates a post which then will be broadcasted
      conn = Phoenix.ConnTest.build_conn()

      assert %{
               "result" => %{
                 "approved?" => true,
                 "body" => nil,
                 "id" => post_id,
                 "location" => %{
                   "coordinates" => [30.0, 30.0],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "private?" => false,
                 "title" => "some regular post",
                 "type" => "regular"
               },
               "success" => true
             } =
               conn
               |> put_req_header("authorization", "Bearer #{insert(:auth_token).key}")
               |> post(Routes.post_path(conn, :create), %{
                 "type" => "regular",
                 "location" => [30.0, 30.0],
                 "title" => "some regular post"
               })
               |> json_response(200)

      assert_push("post:new", push)

      assert %{
               "post" => %{
                 approved?: true,
                 author: %{
                   id: _author_id
                 },
                 fake_location?: false,
                 id: ^post_id,
                 location: %{
                   coordinates: [30.0, 30.0],
                   crs: %{properties: %{name: "EPSG:4326"}, type: "name"},
                   type: "Point"
                 },
                 private?: false,
                 title: "some regular post",
                 type: "regular"
               }
             } = push
    end

    test "when post comes from outside of range", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      # creates a post which then will be broadcasted
      conn = Phoenix.ConnTest.build_conn()

      assert %{
               "result" => %{
                 "approved?" => true,
                 "body" => nil,
                 "id" => post_id,
                 "location" => %{
                   "coordinates" => [50.0, 50.0],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "private?" => false,
                 "title" => "some regular post",
                 "type" => "regular"
               },
               "success" => true
             } =
               conn
               |> put_req_header("authorization", "Bearer #{insert(:auth_token).key}")
               |> post(Routes.post_path(conn, :create), %{
                 "type" => "regular",
                 "location" => [50.0, 50.0],
                 "title" => "some regular post"
               })
               |> json_response(200)

      refute_push("post:new", %{})
    end

    test "when post of blocked user comes from within range", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      [blocked_auth_token, blocker_auth_token] = insert_list(2, :auth_token)

      BillBored.User.Blocks.block(socket.assigns[:user], blocked_auth_token.user)
      BillBored.User.Blocks.block(blocker_auth_token.user, socket.assigns[:user])

      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header("authorization", "Bearer #{blocked_auth_token.key}")
      |> post(Routes.post_path(conn, :create), %{
        "type" => "regular",
        "location" => [30.0, 30.0],
        "title" => "Post from blocked user"
      })
      |> json_response(200)

      refute_push("post:new", _)

      conn
      |> put_req_header("authorization", "Bearer #{blocker_auth_token.key}")
      |> post(Routes.post_path(conn, :create), %{
        "type" => "regular",
        "location" => [30.0, 30.0],
        "title" => "Post from blocker user"
      })
      |> json_response(200)

      refute_push("post:new", _)
    end

    test "when post is updated", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      %{id: post_id} = post = insert(:post, location: [30.0, 30.0])
      auth_token = insert(:auth_token, user: post.author)

      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header("authorization", "Bearer #{auth_token.key}")
      |> put(Routes.post_path(conn, :update, post_id), %{"title" => "new title"})
      |> json_response(200)

      assert_push("post:update", push)

      string_id = to_string(post_id)
      assert %{"changes" => %{title: "new title"}, "id" => ^string_id} = push
    end

    test "when blocked user post is updated", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      %{id: post_id} = post = insert(:post, location: [30.0, 30.0])
      auth_token = insert(:auth_token, user: post.author)

      BillBored.User.Blocks.block(socket.assigns[:user], post.author)

      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header("authorization", "Bearer #{auth_token.key}")
      |> put(Routes.post_path(conn, :update, post_id), %{"title" => "new title"})
      |> json_response(200)

      refute_push("post:update", _push)
    end

    test "when user who blocked us updates his post", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      %{id: post_id} = post = insert(:post, location: [30.0, 30.0])
      auth_token = insert(:auth_token, user: post.author)

      BillBored.User.Blocks.block(post.author, socket.assigns[:user])

      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header("authorization", "Bearer #{auth_token.key}")
      |> put(Routes.post_path(conn, :update, post_id), %{"title" => "new title"})
      |> json_response(200)

      refute_push("post:update", _push)
    end

    test "when post is deleted", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      %{id: post_id} = post = insert(:post, location: [30.0, 30.0])
      auth_token = insert(:auth_token, user: post.author)

      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header("authorization", "Bearer #{auth_token.key}")
      |> delete(Routes.post_path(conn, :delete, post.id))
      |> response(204)

      assert_push("post:delete", %{"id" => ^post_id})
    end

    test "when post of blocked user is deleted", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      post = insert(:post, location: [30.0, 30.0])
      auth_token = insert(:auth_token, user: post.author)

      BillBored.User.Blocks.block(socket.assigns[:user], post.author)

      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header("authorization", "Bearer #{auth_token.key}")
      |> delete(Routes.post_path(conn, :delete, post.id))
      |> response(204)

      refute_push("post:delete", _push)
    end

    test "when user who blocked us deletes his post", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_regular_params({30.0, 30.0}))

      post = insert(:post, location: [30.0, 30.0])
      auth_token = insert(:auth_token, user: post.author)

      BillBored.User.Blocks.block(post.author, socket.assigns[:user])

      conn = Phoenix.ConnTest.build_conn()

      conn
      |> put_req_header("authorization", "Bearer #{auth_token.key}")
      |> delete(Routes.post_path(conn, :delete, post.id))
      |> response(204)

      refute_push("post:delete", _push)
    end
  end

  describe "post cluster markers (enabled)" do
    setup(context) do
      location = %BillBored.Geo.Point{lat: 51.13606981407861, long: -0.17065179253916085}
      radius = 8000

      now = DateTime.utc_now()

      # p1 is outside of the radius, but inside of the geohash of length 5
      p1 = insert(:post, inserted_at: Timex.shift(now, minutes: -1), location: %BillBored.Geo.Point{lat: 51.23399, long: -0.138531})

      # p2, p3, p4, p5 are inside of the radius

      # p2 and p3 are in the same geohash of length 5
      p2 = insert(:post, type: "event", inserted_at: now, location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037})
      insert(:event, post: p2, date: Timex.shift(now, hours: -5))

      p3 = insert(:post, type: "event", inserted_at: now, location: %BillBored.Geo.Point{lat: 51.188059, long: -0.139366})
      insert(:event, post: p3, date: Timex.shift(now, hours: 1))

      {:ok, context} = connect(context)
      Map.merge(context, %{location: location, radius: radius, posts: [p1, p2, p3]})
    end

    test "markers are pushed after join", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket,
      posts: [_p1, %{id: p2_id}, %{id: p3_id}]
    } do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", Map.merge(join_params({lat, lon}, radius), %{"enable_markers" => true}))

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

      assert [
        %{id: ^p3_id},
        %{id: ^p2_id}
      ] = top_posts
    end

    test "markers are pushed after location is updated", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket,
      posts: [_p1, _p2, _p3]
    } do
      {:ok, _reply, socket} =
        subscribe_and_join(socket, "posts", Map.merge(join_params({lat, lon}, radius), %{"enable_markers" => true}))

      assert_push("markers", %{markers: [_m1]})

      %{id: post_id} = post = insert(:post, type: "event")

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

    test "markers are pushed after filter is updated", %{
      location: %BillBored.Geo.Point{long: lon, lat: lat},
      radius: radius,
      socket: socket,
      posts: [p1, _p2, _p3]
    } do
      {:ok, _reply, socket} =
        subscribe_and_join(socket, "posts", Map.merge(join_params({lat, lon}, radius), %{"enable_markers" => true}))

      assert_push("markers", %{markers: [_m1]})

      %{id: post_id} = post = insert(:post, type: "event", location: p1.location)
      insert(:event, post: post, title: "Thames Kayaking")

      ref = push(socket, "filter:update", %{"filter" => %{"keyword" => "kayak"}})
      assert_reply(ref, :ok, %{})

      assert_push("markers", %{markers: [m1]})

      assert %{
        location: %{
          coordinates: [51.23399, -0.138531]
        },
        location_geohash: "gcpgkyg5egzy",
        precision: 5,
        posts_count: 1,
        top_posts: [
          %{id: ^post_id}
        ]
      } = m1
    end
  end

  describe "post cluster markers (disabled)" do
    setup [:connect]

    test "markers are not pushed after join", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "posts", join_params())

      refute_push("markers", _)
    end
  end

  defp connect(_context) do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})
    {:ok, %{user: user, socket: socket}}
  end

  defp join(%{socket: socket}) do
    {:ok, _reply, socket} = subscribe_and_join(socket, "posts", join_params())
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), socket.channel_pid)
    {:ok, %{socket: socket}}
  end

  defp join_with_regular_post_type(%{socket: socket}) do
    {:ok, _reply, socket} = subscribe_and_join(socket, "posts", join_regular_params())
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), socket.channel_pid)
    {:ok, %{socket: socket}}
  end

  defp add_statistics(post) do
    %{post | comments_count: 0, downvotes_count: 0, upvotes_count: 0}
  end

  # defp create_posts(_context) do
  #   # inserts a few posts to search through
  #   p1 = insert(:post, type: "regular", location: point({40.5, -50.0}))
  #   p2 = insert(:post, type: "regular", location: point({40.5001, -50.0001}))

  #   # shouldn't be found (too far)
  #   _p = insert(:post, type: "regular", location: point({0, 0}))
  #   # shouldn't be found, created more than 24h ago
  #   _pp =
  #     insert(
  #       :post,
  #       type: "regular",
  #       location: point({40.51, -50.0}),
  #       inserted_at: into_past(DateTime.utc_now(), 2)
  #     )

  #   # shouldn't be found, event post type
  #   _pee = insert(:post, location: point({40.5001, -50.0001}))

  #   # pe =
  #   #   insert(
  #   #     :post,
  #   #     location: point({40.51, -50.0}),
  #   #     inserted_at: into_past(DateTime.utc_now(), 2)
  #   #   )

  #   # _e =
  #   #   insert(
  #   #     :event,
  #   #     post: pe,
  #   #     date: into_future(DateTime.utc_now(), 2),
  #   #     location: point({0, 0})
  #   #   )

  #   posts =
  #     Enum.map([p1, p2], fn post ->
  #       %{post | downvotes_count: 0, upvotes_count: 0, comments_count: 0}
  #     end)

  #   {:ok, %{posts: posts}}
  # end

  defp create_event_posts(_context) do
    # TODO is it a no longer required feature?
    # shouldn't be found, no associated events
    # _p1 = insert(:post, type: "event", location: point({40.5, -50.0}))
    # _p2 = insert(:post, type: "event", location: point({40.5001, -50.0001}))

    # shouldn't be found, other type
    _p3 = insert(:post, type: "regular", location: point({40.5, -50.0}))
    _p4 = insert(:post, type: "regular", location: point({40.5001, -50.0001}))

    # shouldn't be found (too far)
    _p5 = insert(:post, type: "event", location: point({0.0, 0.0}))

    # shouldn't be found, created more than 24h ago
    _p6 =
      insert(
        :post,
        type: "event",
        location: point({40.5, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    # same created date as p6 above, but should be found with event.date in the future
    p7 =
      insert(
        :post,
        type: "event",
        location: point({40.5, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    e1 =
      insert(
        :event,
        post: p7,
        date: into_future(DateTime.utc_now(), 2),
        other_date: into_future(DateTime.utc_now(), 3),
        location: point({0.0, 0.0})
      )

    p7 = %{p7 | events: [e1]}

    # should be found with event.date 3h in the past
    p8 =
      insert(
        :post,
        type: "event",
        location: point({40.5, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    e2 =
      insert(
        :event,
        post: p8,
        date: into_past_hours(DateTime.utc_now(), 4),
        other_date: into_past_hours(DateTime.utc_now(), 3),
        location: point({0.0, 0.0})
      )

    insert(:event_attendant, event: e2, status: "accepted")

    p8 = %{p8 | events: [e2]}

    # should not be found with event.date in the past
    p9 =
      insert(
        :post,
        type: "event",
        location: point({40.5, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    _e3 =
      insert(
        :event,
        post: p9,
        date: into_past(DateTime.utc_now(), 1),
        location: point({0.0, 0.0})
      )

    posts =
      Enum.map([p7, p8], fn post ->
        %{post | downvotes_count: 0, upvotes_count: 0, comments_count: 0}
      end)

    {:ok, %{event_posts: posts}}
  end

  defp join_params(coordinates \\ {0, 0}, radius \\ 1000) do
    %BillBored.Geo.Point{lat: lat, long: long} = point(coordinates)
    # simulating the client sending the coords in flipped order (lat, long)
    # instead of the correct (long, lat)
    geometry = Geo.JSON.encode!(%Geo.Point{coordinates: {lat, long}})

    %{
      "radius" => radius,
      "geometry" => geometry,
      "post_types" => ["event"]
    }
  end

  defp join_regular_params(coordinates \\ {0, 0}, radius \\ 1000) do
    %{join_params(coordinates, radius) | "post_types" => ["regular"]}
  end

  defp point({lat, long}) do
    %BillBored.Geo.Point{lat: lat, long: long}
  end

  @spec into_past(DateTime.t(), pos_integer) :: DateTime.t()
  defp into_past(daytime, days) do
    DateTime.from_unix!(DateTime.to_unix(daytime) - days * 24 * 60 * 60)
  end

  @spec into_past_hours(DateTime.t(), pos_integer) :: DateTime.t()
  defp into_past_hours(daytime, hours) do
    DateTime.from_unix!(DateTime.to_unix(daytime) - hours * 60 * 60)
  end

  @spec into_future(DateTime.t(), pos_integer) :: DateTime.t()
  defp into_future(daytime, days) do
    DateTime.from_unix!(DateTime.to_unix(daytime) + days * 24 * 60 * 60)
  end
end
