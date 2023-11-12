defmodule Web.PersonalizedPostChannelTest do
  use Web.ChannelCase, async: true
  alias BillBored.User

  describe "join" do
    setup [:connect]

    test "with valid params assigns params to socket ", %{socket: socket} do
      geo = %{"type" => "Point", "coordinates" => [30.700873561540504, 76.788390984195786]}

      params = %{
        "radius" => 5819.68555,
        "geometry" => geo,
        "post_types" => ["regular"]
      }

      {:ok, _reply, updated_socket} = subscribe_and_join(socket, "personalized", params)

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
               subscribe_and_join(socket, "personalized", %{})
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
    setup [:connect, :join, :create_events]

    # test "location point", %{socket: socket, events: events} do
    #   ref =
    #     push(socket, "posts:list", %{
    #       "geometry" => %{"type" => "Point", "coordinates" => [40.5, -50.0]}
    #     })

    #   assert_reply(ref, :ok, %{posts: received_posts})

    #   assert length(received_posts) ==
    #            length(Phoenix.View.render_many(events, Web.PostView, "show.json", %{user_id: socket.assigns.user.id}))
    # end

    # test "location polygon", %{socket: socket, events: events} do
    #   ref =
    #     push(socket, "posts:list", %{
    #       "geometry" => %{
    #         "type" => "Polygon",
    #         "coordinates" => [
    #           [
    #             [40.0, -49.0],
    #             [40.0, -55.0],
    #             [50.7, -55.0],
    #             [50.7, -49.0],
    #             [40.0, -49.0]
    #           ]
    #         ]
    #       }
    #     })

    #   assert_reply(ref, :ok, %{posts: received_posts})

    #   assert length(received_posts) ==
    #            length(Phoenix.View.render_many(events, Web.PostView, "show.json", %{user_id: socket.assigns.user.id}))
    # end
  end

  describe "posts query" do
    setup [:connect, :join_with_regular_post_type, :create_posts]

    # TODO: uncomment
    # test "location point", %{socket: socket, posts: posts} do
    #   ref =
    #     push(socket, "posts:list", %{
    #       "geometry" => %{"type" => "Point", "coordinates" => [40.5, -50.0]}
    #     })

    #   assert_reply(ref, :ok, %{posts: received_posts})
    #   assert received_posts == Phoenix.View.render_many(posts, Web.PostView, "show.json", %{user_id: socket.assigns.user.id})
    # end

    # test "location polygon", %{socket: socket, posts: posts} do
    #   ref =
    #     push(socket, "posts:list", %{
    #       "geometry" => %{
    #         "type" => "Polygon",
    #         "coordinates" => [
    #           [
    #             [40.0, -49.0],
    #             [40.0, -55.0],
    #             [50.7, -55.0],
    #             [50.7, -49.0],
    #             [40.0, -49.0]
    #           ]
    #         ]
    #       }
    #     })

    #   assert_reply(ref, :ok, %{posts: received_posts})
    #   assert received_posts == Phoenix.View.render_many(posts, Web.PostView, "show.json", %{user_id: socket.assigns.user.id})
    # end
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
        subscribe_and_join(socket, "personalized", Map.merge(join_params({lat, lon}, radius), %{"enable_markers" => true}))

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
        subscribe_and_join(socket, "personalized", Map.merge(join_params({lat, lon}, radius), %{"enable_markers" => true}))

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
  end

  describe "post cluster markers (disabled)" do
    setup [:connect]

    test "markers are not pushed after join", %{socket: socket} do
      {:ok, _reply, _socket} =
        subscribe_and_join(socket, "personalized", join_params())

      refute_push("markers", _)
    end
  end

  defp connect(_context) do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})
    {:ok, %{user: user, socket: socket}}
  end

  defp join(%{socket: socket}) do
    {:ok, _reply, socket} = subscribe_and_join(socket, "personalized", join_params())
    {:ok, %{socket: socket}}
  end

  defp join_with_regular_post_type(%{socket: socket}) do
    {:ok, _reply, socket} = subscribe_and_join(socket, "personalized", join_regular_params())
    {:ok, %{socket: socket}}
  end

  defp create_posts(%{user: user}) do
    # should be found with author is a user's friend
    author = insert(:user)
    insert(:user_friendship, users: [user, author])
    p1 = insert(:post, type: "regular", user: author, location: point({40.5, -50.0}))

    # should be found, user has the same interest as mentioned in post
    p2 = insert(:post, type: "regular", location: point({40.5001, -50.0001}))
    i = insert(:interest)
    insert(:post_interest, post: p2, interest: i)
    insert(:user_interest, user: user, interest: i)

    # should be found with author is a user's following
    author1 = insert(:user)
    insert(:user_following, from_user: user, to_user: author1)
    p3 = insert(:post, type: "regular", user: author1, location: point({40.5, -50.0}))

    # should not be found^ author is a user's follower
    author2 = insert(:user)
    insert(:user_following, to_user: user, from_user: author2)
    _p = insert(:post, type: "regular", author: author2, location: point({40.5, -50.0}))

    # shouldn't be found, no friend or interest matched
    _pp = insert(:post, type: "regular", location: point({40.5, -50.0}))

    # shouldn't be found because of location
    _ppp = insert(:post, type: "regular", author: author, location: point({0, 0}))
    # shouldn't be found, created more than 24h ago
    _pppp =
      insert(
        :post,
        type: "regular",
        author: author,
        location: point({40.51, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    # should not be found, other type
    p4 =
      insert(
        :post,
        type: "regular",
        author: author,
        location: point({40.51, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    _e =
      insert(
        :event,
        post: p4,
        date: into_future(DateTime.utc_now(), 2),
        location: point({0, 0})
      )

    posts =
      Enum.map([p1, p2, p3], fn post ->
        %{post | downvotes_count: 0, upvotes_count: 0, comments_count: 0}
      end)

    {:ok, %{posts: posts}}
  end

  defp create_events(%{user: user}) do
    author = insert(:user)
    insert(:user_friendship, users: [user, author])

    # shouldn't be found, no associated events
    _p1 = insert(:post, author: author, location: point({40.5, -50.0}))
    _p2 = insert(:post, author: author, location: point({40.5001, -50.0001}))

    # shouldn't be found, other type
    _pr1 = insert(:post, author: author, type: "regular", location: point({40.5, -50.0}))

    _pr2 = insert(:post, author: author, type: "regular", location: point({40.5001, -50.0001}))

    # shouldn't be found (too far)
    _p = insert(:post, author: author, location: point({0, 0}))

    # should be found with friendship and event.date in the future
    p4 =
      insert(
        :post,
        author: author,
        location: point({40.51, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    _e =
      insert(
        :event,
        post: p4,
        date: into_future(DateTime.utc_now(), 2),
        location: point({0, 0})
      )

    # should be found with event.date less then 12h in the past
    p5 =
      insert(
        :post,
        author: author,
        location: point({40.51, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    _ee =
      insert(
        :event,
        post: p5,
        date: into_past_hours(DateTime.utc_now(), 3),
        location: point({0, 0})
      )

    # should be found with interest and event.date in the future
    p6 = insert(:post, location: point({40.5001, -50.0001}))
    i = insert(:interest)
    insert(:post_interest, post: p6, interest: i)
    insert(:user_interest, user: user, interest: i)

    _e =
      insert(
        :event,
        post: p6,
        date: into_future(DateTime.utc_now(), 2),
        location: point({0, 0})
      )

    # should not be found with event.date in the past
    p7 =
      insert(
        :post,
        location: point({40.51, -50.0}),
        inserted_at: into_past(DateTime.utc_now(), 2)
      )

    insert(:post_interest, post: p7, interest: i)

    _ee =
      insert(
        :event,
        post: p7,
        date: into_past(DateTime.utc_now(), 1),
        location: point({0, 0})
      )

    # should be found with author is a user's following and event.date in the future
    author1 = insert(:user)
    insert(:user_following, from_user: user, to_user: author1)
    p8 = insert(:post, author: author1, location: point({40.5, -50.0}))

    _e =
      insert(
        :event,
        post: p8,
        date: into_future(DateTime.utc_now(), 2),
        location: point({0, 0})
      )

    # should not be found with author is a user's following but event.date in the past
    p9 = insert(:post, author: author1, location: point({40.5, -50.0}))

    _e =
      insert(
        :event,
        post: p9,
        date: into_past(DateTime.utc_now(), 1),
        location: point({0, 0})
      )

    # should not be found^ author is a user's follower
    author2 = insert(:user)
    insert(:user_following, to_user: user, from_user: author2)
    p10 = insert(:post, author: author2, location: point({40.5, -50.0}))

    _e =
      insert(
        :event,
        post: p10,
        date: into_future(DateTime.utc_now(), 2),
        inserted_at: point({0, 0})
      )

    events =
      Enum.map([p4, p5, p6, p8], fn post ->
        %{post | downvotes_count: 0, upvotes_count: 0, comments_count: 0}
      end)

    {:ok, %{events: events}}
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
