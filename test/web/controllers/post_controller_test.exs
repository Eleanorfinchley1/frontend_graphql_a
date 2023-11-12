defmodule Web.PostControllerTest do
  use Web.ConnCase, async: true

  import BillBored.Factory
  import BillBored.ServiceRegistry, only: [replace: 2]

  alias BillBored.{User, Post}

  @attrs %{
    "title" => "Pollrtrtr",
    "private?" => false,
    "type" => "regular",
    "media_file_keys" => [],
    "polls" => [
      %{
        "question" => "Are you alive?",
        "items" => [
          "Yes!",
          %{"title" => "No!", "media_file_keys" => []}
        ]
      }
    ],
    "location" => [30.7008, 76.7885],
    "body" => "Wegerger her ",
    #    "fake?" => true,
    "interests" => ["#oh-no!", %{"hashtag" => "#oh-yes!"}]
  }

  describe "posts" do
    setup [:create_users]

    test "returned paginated", %{conn: conn, tokens: tokens} do
      [author1, author2 | _] = tokens

      for _ <- 1..10, do: insert(:post, author: author1.user, type: "vote")
      for _ <- 1..20, do: insert(:post, author: author1.user, type: "regular")
      for _ <- 1..30, do: insert(:post, author: author1.user, type: "poll")
      for _ <- 1..40, do: insert(:post, author: author1.user, type: "event")

      for _ <- 1..29, do: insert(:post, author: author2.user)

      resp =
        conn
        |> authenticate(author1)
        |> get(Routes.post_path(conn, :index_for_user))
        |> json_response(200)

      assert resp["total_entries"] == 100

      resp =
        conn
        |> authenticate(author2)
        |> get(Routes.post_path(conn, :index_for_user))
        |> json_response(200)

      assert resp["total_entries"] == 29

      resp =
        conn
        |> authenticate(author1)
        |> get(Routes.post_path(conn, :index, author2.user.id))
        |> json_response(200)

      assert resp["total_entries"] == 29

      resp =
        conn
        |> authenticate(author2)
        |> get(Routes.post_path(conn, :index, author1.user.id))
        |> json_response(200)

      assert resp["total_entries"] == 100

      resp =
        conn
        |> authenticate(author2)
        |> get(Routes.post_path(conn, :index, author1.user.id, type: "vote"))
        |> json_response(200)

      assert resp["total_entries"] == 10

      resp =
        conn
        |> authenticate(author2)
        |> get(Routes.post_path(conn, :index, author1.user.id, type: "regular"))
        |> json_response(200)

      assert resp["total_entries"] == 20

      resp =
        conn
        |> authenticate(author2)
        |> get(Routes.post_path(conn, :index, author1.user.id, type: "poll"))
        |> json_response(200)

      assert resp["total_entries"] == 30

      resp =
        conn
        |> authenticate(author2)
        |> get(Routes.post_path(conn, :index, author1.user.id, type: "event"))
        |> json_response(200)

      assert resp["total_entries"] == 40
    end
  end

  defmodule Stubs.PlacesAPI do
    def search(%{long: long, lat: lat}, _dist, _opts) do
      place = insert(:place, location: %BillBored.Geo.Point{lat: lat + 0.005, long: long + 0.005})
      {:ok, [place]}
    end
  end

  describe "post" do
    setup [:create_users]

    test "can be created", %{conn: conn, tokens: [token | _]} do
      assert %{
               "success" => true,
               "result" => post
             } =
               conn
               |> authenticate(token)
               |> post(Routes.post_path(conn, :create), @attrs)
               |> json_response(200)

      assert %Post{
               location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
               location_geohash: 929_672_732_190_750_713
             } = Repo.get!(Post, post["id"])
    end

    test "can be created with fake location", %{conn: conn, tokens: [token | _]} do
      replace(BillBored.Place.GoogleApi.Places, Stubs.PlacesAPI)

      assert %{
               "success" => true,
               "result" => post
             } =
               conn
               |> authenticate(token)
               |> post(Routes.post_path(conn, :create), Map.merge(@attrs, %{"fake" => true}))
               |> json_response(200)

      assert %Post{
               location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
               fake_location: %BillBored.Geo.Point{lat: 30.7058, long: 76.7935},
               location_geohash: 929_672_733_781_022_719
             } = Repo.get!(Post, post["id"])
    end

    test "can be deleted", %{conn: conn, tokens: tokens} do
      [author, token | _] = tokens

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(token)
        |> delete(Routes.post_path(conn, :delete, 123))
      end

      resp =
        conn
        |> authenticate(author)
        |> post(Routes.post_path(conn, :create), @attrs)
        |> json_response(200)

      assert resp["result"] && resp["success"]
      post = resp["result"]

      resp =
        conn
        |> authenticate(author)
        |> post(Routes.post_path(conn, :create), %{
          @attrs
          | "interests" => ["  oh  no!", "##google", "wow # kills"]
        })
        |> json_response(200)

      assert resp["result"]["interests"] == ["oh-no!", "google", "wow-kills"]

      conn
      |> authenticate(token)
      |> delete(Routes.post_path(conn, :delete, post["id"]))
      |> response(403)

      conn
      |> authenticate(author)
      |> delete(Routes.post_path(conn, :delete, post["id"]))
      |> response(204)

      assert length(Repo.all(Post.Interest)) == 3

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(author)
        |> delete(Routes.post_path(conn, :delete, post["id"]))
      end

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(author)
        |> get(Routes.post_path(conn, :show, post["id"]))
      end
    end

    test "can be updated", %{conn: conn, tokens: [author, token | _]} do
      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(token)
        |> put(Routes.post_path(conn, :update, 123))
      end

      resp =
        conn
        |> authenticate(author)
        |> post(Routes.post_path(conn, :create), @attrs)
        |> json_response(200)

      assert resp["result"] && resp["success"]

      post = resp["result"]

      params = %{
        @attrs
        | "body" => "New b o d y!",
          "interests" => ["holliday", "money", "piece"],
          "location" => [15.6773, 45.6734]
      }

      conn
      |> authenticate(token)
      |> put(Routes.post_path(conn, :update, post["id"]), params)
      |> response(403)

      resp =
        conn
        |> authenticate(author)
        |> put(Routes.post_path(conn, :update, post["id"]), params)
        |> json_response(200)

      assert resp["result"] && resp["success"]

      assert resp["result"]["id"] == post["id"]
      assert resp["result"]["body"] == "New b o d y!"
      assert resp["result"]["interests"] == ["holliday", "money", "piece"]

      post =
        conn
        |> authenticate(author)
        |> get(Routes.post_path(conn, :show, post["id"]))
        |> json_response(200)

      refute post["result"] || post["success"]
      assert post["interests"] == ["holliday", "money", "piece"]

      assert %{
               body: "New b o d y!",
               interests: interests,
               location: %BillBored.Geo.Point{lat: 15.6773, long: 45.6734},
               location_geohash: 905_579_409_806_182_819
             } = Repo.get!(Post, post["id"]) |> Repo.preload([:interests])

      assert ["holliday", "money", "piece"] == Enum.map(interests, & &1.hashtag)
    end
  end

  describe "upvote/downvote/unvote" do
    setup [:create_users]

    test "are working as expected", %{conn: conn, tokens: tokens} do
      [author, token2, token3 | _] = tokens

      post = insert(:post, author: author.user)

      vote = fn token, action ->
        conn
        |> authenticate(token)
        |> post(Routes.post_path(conn, :vote, post.id, %{"action" => action}))
        |> response(204)

        conn
        |> authenticate(token)
        |> get(Routes.post_path(conn, :show, post.id))
        |> response(200)
        |> Jason.decode!()
      end

      make_twice = fn token, action ->
        vote.(token, action)

        # and again:
        vote.(token, action)
      end

      # upvote

      resp = make_twice.(token2, "upvote")
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 0

      resp =
        conn
        |> authenticate(token3)
        |> get(Routes.post_path(conn, :show, post.id))
        |> response(200)
        |> Jason.decode!()

      assert resp["user_upvoted?"] == false
      assert resp["user_downvoted?"] == false

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_path(conn, :show, post.id))
        |> response(200)
        |> Jason.decode!()

      assert resp["user_upvoted?"] == true
      assert resp["user_downvoted?"] == false

      resp = make_twice.(token2, "downvote")
      assert resp["upvotes_count"] == 0
      assert resp["downvotes_count"] == 1

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_path(conn, :show, post.id))
        |> response(200)
        |> Jason.decode!()

      assert resp["user_upvoted?"] == false
      assert resp["user_downvoted?"] == true

      # downvote

      resp = make_twice.(token3, "upvote")
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 1

      resp = make_twice.(token3, "downvote")
      assert resp["upvotes_count"] == 0
      assert resp["downvotes_count"] == 2

      # making upvote for the author

      resp = vote.(author, "upvote")
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 2

      # unvote

      unvote = &vote.(&1, "unvote")

      resp = unvote.(token2)
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 1

      resp = unvote.(token3)
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 0

      resp = unvote.(author)
      assert resp["upvotes_count"] == 0
      assert resp["downvotes_count"] == 0
    end
  end

  defmodule Stubs.Clickhouse.PostViews do
    def create(post_view) do
      send(self(), {__MODULE__, :create, {post_view}})
    end
  end

  describe "event post" do
    setup %{conn: conn} do
      token = insert(:auth_token)
      date = DateTime.utc_now() |> DateTime.add(3 * 24 * 60 * 60)
      other_date = DateTime.add(date, 24 * 60 * 60)
      {:ok, conn: authenticate(conn, token), user: token.user, date: date, other_date: other_date}
    end

    test "create using flat request body", %{conn: conn, date: date, other_date: other_date} do
      conn =
        post(conn, Routes.post_path(conn, :create), %{
          "location" => [30.7132777, 76.8505598],
          "private?" => false,
          "title" => "Event New Fields",
          "buy_ticket_link" => "https://www.xyz.com/ticket",
          "price" => 25.0,
          "currency" => "USD",
          "date" => DateTime.to_iso8601(date),
          "event_location" => [30.7132777, 76.8505598],
          "media_file_keys" => [],
          "child_friendly" => true,
          "other_date" => DateTime.to_iso8601(other_date),
          "body" => "Test description... #win-or-die, #googling",
          "interests" => ["win-or-die", "googling"],
          "type" => "event",
          "categories" => ["sport", "music"]
        })

      assert %{
               "result" => %{
                 "author" => _author,
                 "body" => "Test description... #win-or-die, #googling",
                 "business" => nil,
                 "business_admin" => nil,
                 "business_name" => nil,
                 "comments_count" => 0,
                 "downvotes_count" => 0,
                 "events" => [
                   %{
                     "accepted_count" => 0,
                     "attendees" => [],
                     "buy_ticket_link" => "https://www.xyz.com/ticket",
                     "child_friendly" => true,
                     "currency" => "USD",
                     "date" => _date,
                     "doubts_count" => 0,
                     "id" => _event_id,
                     "inserted_at" => _event_inserted_at,
                     "invited_count" => 0,
                     "location" => %{
                       "coordinates" => [30.7132777, 76.8505598],
                       "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                       "type" => "Point"
                     },
                     "media_file_keys" => [],
                     "missed_count" => 0,
                     "other_date" => _other_date,
                     "place" => nil,
                     "presented_count" => 0,
                     "price" => 25.0,
                     "refused_count" => 0,
                     "title" => "Event New Fields",
                     "updated_at" => _event_updated_at,
                     "user_attending?" => false,
                     "user_status" => nil,
                     "categories" => ["sport", "music"]
                   }
                 ],
                 "fake_location?" => false,
                 "id" => _post_id,
                 "inserted_at" => _inserted_at,
                 "interests" => ["win-or-die", "googling"],
                 "location" => %{
                   "coordinates" => [30.7132777, 76.8505598],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "media_file_keys" => [],
                 "place" => nil,
                 "polls" => [],
                 "post_cost" => nil,
                 "private?" => false,
                 "title" => "Event New Fields",
                 "type" => "event",
                 "updated_at" => _updated_at,
                 "upvotes_count" => 0,
                 "user_downvoted?" => false,
                 "user_upvoted?" => false
               },
               "success" => true
             } = json_response(conn, 200)
    end

    test "create using nested request body", %{conn: conn, date: date, other_date: other_date} do
      conn =
        post(conn, Routes.post_path(conn, :create), %{
          "location" => [30.7132777, 76.8505598],
          "private?" => false,
          "title" => "Event New Fields",
          "events" => [
            %{
              "title" => "Event New Fields",
              "buy_ticket_link" => "https://www.xyz.com/ticket",
              "price" => 25.0,
              "currency" => "USD",
              "date" => DateTime.to_iso8601(date),
              "location" => [30.7132777, 76.8505598],
              "media_file_keys" => [],
              "child_friendly" => true,
              "other_date" => DateTime.to_iso8601(other_date),
              "categories" => ["sport", "music"]
            }
          ],
          "body" => "Test description... #win-or-die, #googling",
          "interests" => ["win-or-die", "googling"],
          "type" => "event"
        })

      assert %{
               "result" => %{
                 "author" => _author,
                 "body" => "Test description... #win-or-die, #googling",
                 "business" => nil,
                 "business_admin" => nil,
                 "business_name" => nil,
                 "comments_count" => 0,
                 "downvotes_count" => 0,
                 "events" => [
                   %{
                     "accepted_count" => 0,
                     "attendees" => [],
                     "buy_ticket_link" => "https://www.xyz.com/ticket",
                     "child_friendly" => true,
                     "currency" => "USD",
                     "date" => _date,
                     "doubts_count" => 0,
                     "id" => _event_id,
                     "inserted_at" => _event_inserted_at,
                     "invited_count" => 0,
                     "location" => %{
                       "coordinates" => [30.7132777, 76.8505598],
                       "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                       "type" => "Point"
                     },
                     "media_file_keys" => [],
                     "missed_count" => 0,
                     "other_date" => _other_date,
                     "place" => nil,
                     "presented_count" => 0,
                     "price" => 25.0,
                     "refused_count" => 0,
                     "title" => "Event New Fields",
                     "updated_at" => _event_updated_at,
                     "user_attending?" => false,
                     "user_status" => nil,
                     "categories" => ["sport", "music"]
                   }
                 ],
                 "fake_location?" => false,
                 "id" => _post_id,
                 "inserted_at" => _inserted_at,
                 "interests" => ["win-or-die", "googling"],
                 "location" => %{
                   "coordinates" => [30.7132777, 76.8505598],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "media_file_keys" => [],
                 "place" => nil,
                 "polls" => [],
                 "post_cost" => nil,
                 "private?" => false,
                 "title" => "Event New Fields",
                 "type" => "event",
                 "updated_at" => _updated_at,
                 "upvotes_count" => 0,
                 "user_downvoted?" => false,
                 "user_upvoted?" => false
               },
               "success" => true
             } = json_response(conn, 200)
    end

    test "returns nested event statistics", %{
      conn: conn,
      user: %{id: user_id} = user
    } do
      event = insert(:event)
      post = insert(:post, events: [event])
      insert(:event_attendant, status: "accepted", user: user, event: event)

      assert %{
               "events" => [
                 %{
                   "accepted_count" => 1,
                   "attendees" => [
                     %{
                       "id" => ^user_id
                     }
                   ],
                   "doubts_count" => 0,
                   "invited_count" => 0,
                   "missed_count" => 0,
                   "presented_count" => 0,
                   "refused_count" => 0,
                   "user_attending?" => true,
                   "user_status" => "accepted"
                 }
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :show, post.id))
               |> json_response(200)
    end

    test "returns nested poll statistics", %{conn: conn, user: user} do
      %{items: [i1, _i2, _i3], id: poll_id, question: poll_question} = poll = insert(:poll)
      insert(:poll_item_vote, user: user, poll_item: i1)
      %{id: post_id} = post = insert(:post, polls: [poll])

      assert %{
               "polls" => [
                 %{
                   "id" => ^poll_id,
                   "items" => [
                     %{
                       "media_file_keys" => [],
                       "title" => "Yes",
                       "user_voted?" => true,
                       "votes_count" => 1
                     },
                     %{
                       "media_file_keys" => [],
                       "title" => "Maybe",
                       "user_voted?" => false,
                       "votes_count" => 0
                     },
                     %{
                       "media_file_keys" => [],
                       "title" => "No",
                       "user_voted?" => false,
                       "votes_count" => 0
                     }
                   ],
                   "post_id" => ^post_id,
                   "question" => ^poll_question
                 }
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :show, post.id))
               |> json_response(200)
    end

    test "tracks view", %{conn: conn, user: %{sex: user_sex, id: user_id} = user} do
      replace(BillBored.Clickhouse.PostViews, Stubs.Clickhouse.PostViews)

      %{id: post_id} = post = insert(:post)

      conn
      |> get(
        Routes.post_path(conn, :show, post.id),
        %{
          "lon" => "-73.935242",
          "lat" => "40.730610",
          "country" => "USA",
          "city" => "New York"
        }
      )
      |> doc()
      |> json_response(200)

      assert_received {Stubs.Clickhouse.PostViews, :create,
                       {%BillBored.Clickhouse.PostView{
                          post_id: ^post_id,
                          geohash: "dr5rtwccpbpb",
                          lat: 40.730610,
                          lon: -73.935242,
                          country: "USA",
                          city: "New York",
                          user_id: ^user_id,
                          business_id: nil,
                          age: age,
                          sex: ^user_sex
                        }}}

      assert age == Timex.diff(DateTime.utc_now(), user.birthdate, :years)
    end
  end

  # TODO simplify with proper fixtures and setup blocks
  describe "business post" do
    use Phoenix.ChannelTest

    defp join_notifications_channel(%User.AuthToken{user: %User{} = user, key: token}) do
      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})
      subscribe_and_join(socket, "notifications:#{user.id}", %{})
    end

    test "create when user is owner", %{conn: conn} do
      %{member: owner, business_account: business_account} =
        insert(:user_membership, role: "owner")

      conn =
        conn
        |> authenticate(insert(:auth_token, user: owner))
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })

      assert %{
               "result" => %{
                 "author" => %{
                   "id" => author_id
                 },
                 "body" => "Weherhrth ",
                 "business" => %{"id" => business_id},
                 "business_admin" => %{"id" => business_admin_id},
                 "business_name" => business_name,
                 "comments_count" => 0,
                 "downvotes_count" => 0,
                 "events" => [],
                 "fake_location?" => false,
                 "id" => _post_id,
                 "inserted_at" => _,
                 "interests" => [],
                 "location" => %{
                   "coordinates" => [30.7008, 76.7885],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "media_file_keys" => [],
                 "place" => nil,
                 "polls" => [],
                 # TODO post cost shouldn't be nil?
                 "post_cost" => nil,
                 "private?" => false,
                 "title" => "Business thought",
                 "type" => "regular",
                 "updated_at" => _,
                 "upvotes_count" => 0,
                 "user_downvoted?" => false,
                 "user_upvoted?" => false,
                 "approved?" => true
               },
               "success" => true
             } = json_response(conn, 200)

      assert business_id == business_account.id
      assert author_id == business_account.id
      assert business_name == business_account.username
      # TODO why is it so?
      assert business_admin_id == business_account.id
    end

    test "create when user is admin", %{conn: conn} do
      %{member: admin, business_account: business_account} =
        insert(:user_membership, role: "admin")

      conn =
        conn
        |> authenticate(insert(:auth_token, user: admin))
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })

      assert %{"success" => true, "result" => %{"approved?" => false, "id" => _post_id}} =
               json_response(conn, 200)
    end

    test "create when user is member", %{conn: conn} do
      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member")

      conn =
        conn
        |> authenticate(insert(:auth_token, user: member))
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })

      assert %{"success" => true, "result" => %{"approved?" => false, "id" => _post_id}} =
               json_response(conn, 200)
    end

    test "create when not required approval", %{conn: conn} do
      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member", required_approval: false)

      conn =
        conn
        |> authenticate(insert(:auth_token, user: member))
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "request approval", %{conn: conn} do
      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member")

      %{member: approver} =
        insert(:user_membership, role: "admin", business_account: business_account)

      conn = authenticate(conn, insert(:auth_token, user: member))
      {:ok, _reply, _socket} = join_notifications_channel(insert(:auth_token, user: approver))

      %{"success" => true, "result" => %{"approved?" => false, "id" => post_id}} =
        conn
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })
        |> json_response(200)

      assert %{"success" => true} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 "post_id" => post_id,
                 "approver_id" => approver.id
               })
               |> json_response(200)

      assert_push("posts:approve:request", push)

      assert push == %{
               "message" => "#{member.username} requested your approval for a post",
               "post_id" => post_id,
               "requester_id" => member.id
             }

      assert request =
               Repo.get_by(Post.ApprovalRequest,
                 approver_id: approver.id,
                 post_id: post_id,
                 requester_id: member.id
               )

      assert %{"reason" => "Approval request already exists", "success" => false} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 "post_id" => post_id,
                 "approver_id" => approver.id
               })
               |> json_response(422)

      refute_push("posts:approve:request", _push)
    end

    test "invalid approval requests", %{conn: conn} do
      import Ecto.Query

      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member")

      %{member: invalid_approver1} =
        insert(:user_membership, role: "member", business_account: business_account)

      %{member: invalid_approver2} = insert(:user_membership, role: "owner")

      %{member: approver} =
        insert(:user_membership, role: "admin", business_account: business_account)

      {:ok, _reply, _socket} = join_notifications_channel(insert(:auth_token, user: approver))

      {:ok, _reply, _socket} =
        join_notifications_channel(insert(:auth_token, user: invalid_approver1))

      {:ok, _reply, _socket} =
        join_notifications_channel(insert(:auth_token, user: invalid_approver2))

      conn = authenticate(conn, insert(:auth_token, user: member))

      %{"success" => true, "result" => %{"approved?" => false, "id" => post_id}} =
        conn
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })
        |> json_response(200)

      assert %{"reason" => "Invalid approver membership role", "success" => false} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 post_id: post_id,
                 approver_id: invalid_approver1.id
               })
               |> json_response(422)

      assert %{"reason" => "Approver membership not found", "success" => false} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 post_id: post_id,
                 approver_id: invalid_approver2.id
               })
               |> json_response(422)

      assert %{"reason" => "Approver membership not found", "success" => false} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 post_id: post_id,
                 approver_id: approver.id + 1
               })
               |> json_response(422)

      assert %{"reason" => "Post not found", "success" => false} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 post_id: post_id + 1,
                 approver_id: approver.id
               })
               |> json_response(422)

      post_query = where(Post, id: ^post_id)

      {1, nil} = Repo.update_all(post_query, set: [approved?: true])

      assert %{"reason" => "Post is already approved", "success" => false} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 post_id: post_id,
                 approver_id: approver.id
               })
               |> json_response(422)

      {1, nil} = Repo.update_all(post_query, set: [approved?: false, business_id: nil])

      assert %{"reason" => "Post is not a business post", "success" => false} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 post_id: post_id,
                 approver_id: approver.id
               })
               |> json_response(422)

      refute_push("posts:approve:request", _push)
    end

    test "approve post request", %{conn: conn} do
      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member")

      %{member: approver} =
        insert(:user_membership, role: "admin", business_account: business_account)

      conn = authenticate(conn, insert(:auth_token, user: member))

      %{"success" => true, "result" => %{"approved?" => false, "id" => post_id}} =
        conn
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })
        |> json_response(200)

      assert %{"success" => true} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 "post_id" => post_id,
                 "approver_id" => approver.id
               })
               |> json_response(200)

      conn = authenticate(conn, insert(:auth_token, user: approver))

      assert %{"success" => true} ==
               conn
               |> post(Routes.post_path(conn, :approve_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id
               })
               |> json_response(200)

      assert %Post{approved?: true} = Repo.get(Post, post_id)

      refute Repo.get_by(Post.ApprovalRequest,
               post_id: post_id,
               requester_id: member.id,
               approver_id: approver.id
             )
    end

    test "invalid approve post request", %{conn: conn} do
      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member")

      %{member: invalid_approver1} =
        insert(:user_membership, role: "member", business_account: business_account)

      %{member: invalid_approver2} = insert(:user_membership, role: "owner")

      %{member: approver} =
        insert(:user_membership, role: "admin", business_account: business_account)

      conn = authenticate(conn, insert(:auth_token, user: member))

      %{"success" => true, "result" => %{"approved?" => false, "id" => post_id}} =
        conn
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })
        |> json_response(200)

      assert %{"success" => true} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 "post_id" => post_id,
                 "approver_id" => approver.id
               })
               |> json_response(200)

      conn = authenticate(conn, insert(:auth_token, user: approver))

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :approve_post), %{
                 "post_id" => post_id + 1,
                 "requester_id" => member.id
               })
               |> json_response(422)

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :approve_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id + 1
               })
               |> json_response(422)

      conn = authenticate(conn, insert(:auth_token, user: invalid_approver1))

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :approve_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id
               })
               |> json_response(422)

      conn = authenticate(conn, insert(:auth_token, user: invalid_approver2))

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :approve_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id
               })
               |> json_response(422)

      assert %Post{approved?: false} = Repo.get(Post, post_id)

      assert Repo.get_by(Post.ApprovalRequest,
               post_id: post_id,
               requester_id: member.id,
               approver_id: approver.id
             )
    end

    test "reject post request", %{conn: conn} do
      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member")

      requester_auth_token = insert(:auth_token, user: member)

      %{member: approver} =
        insert(:user_membership, role: "admin", business_account: business_account)

      conn = authenticate(conn, requester_auth_token)
      {:ok, _reply, _socket} = join_notifications_channel(requester_auth_token)

      %{"success" => true, "result" => %{"approved?" => false, "id" => post_id}} =
        conn
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })
        |> json_response(200)

      assert %{"success" => true} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 "post_id" => post_id,
                 "approver_id" => approver.id
               })
               |> json_response(200)

      conn = authenticate(conn, insert(:auth_token, user: approver))

      assert %{"success" => true} ==
               conn
               |> post(Routes.post_path(conn, :reject_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id,
                 "note" => "not good"
               })
               |> json_response(200)

      assert_push("posts:approve:request:reject", push)

      assert push == %{
               "approver_id" => approver.id,
               "message" => "#{approver.username} rejected your post",
               "post_id" => post_id
             }

      assert %Post{approved?: false} = Repo.get(Post, post_id)

      refute Repo.get_by(Post.ApprovalRequest,
               post_id: post_id,
               requester_id: member.id,
               approver_id: approver.id
             )

      assert %Post.ApprovalRequest.Rejection{note: "not good"} =
               Repo.get_by(Post.ApprovalRequest.Rejection,
                 post_id: post_id,
                 requester_id: member.id,
                 approver_id: approver.id
               )
    end

    test "invalid reject post request", %{conn: conn} do
      %{member: member, business_account: business_account} =
        insert(:user_membership, role: "member")

      requester_auth_token = insert(:auth_token, user: member)

      %{member: invalid_approver1} =
        insert(:user_membership, role: "member", business_account: business_account)

      %{member: invalid_approver2} = insert(:user_membership, role: "owner")

      %{member: approver} =
        insert(:user_membership, role: "admin", business_account: business_account)

      conn = authenticate(conn, requester_auth_token)
      {:ok, _reply, _socket} = join_notifications_channel(requester_auth_token)

      %{"success" => true, "result" => %{"approved?" => false, "id" => post_id}} =
        conn
        |> post(Routes.post_path(conn, :create), %{
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business thought",
          "private" => false,
          "media_file_keys" => [],
          "business_username" => business_account.username,
          "body" => "Weherhrth ",
          "is_business" => true,
          "fake" => false,
          "type" => "regular"
        })
        |> json_response(200)

      assert %{"success" => true} ==
               conn
               |> post(Routes.post_path(conn, :request_approval), %{
                 "post_id" => post_id,
                 "approver_id" => approver.id,
                 "note" => "not good"
               })
               |> json_response(200)

      conn = authenticate(conn, insert(:auth_token, user: approver))

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :reject_post), %{
                 "post_id" => post_id + 1,
                 "requester_id" => member.id,
                 "note" => "not good"
               })
               |> json_response(422)

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :reject_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id + 1,
                 "note" => "not good"
               })
               |> json_response(422)

      conn = authenticate(conn, insert(:auth_token, user: invalid_approver1))

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :reject_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id,
                 "note" => "not good"
               })
               |> json_response(422)

      conn = authenticate(conn, insert(:auth_token, user: invalid_approver2))

      assert %{"success" => false, "reason" => "Approval request not found"} ==
               conn
               |> post(Routes.post_path(conn, :reject_post), %{
                 "post_id" => post_id,
                 "requester_id" => member.id,
                 "note" => "not good"
               })
               |> json_response(422)

      refute_push("posts:approve:request:reject", _push)

      assert %Post{approved?: false} = Repo.get(Post, post_id)

      assert Repo.get_by(Post.ApprovalRequest,
               post_id: post_id,
               requester_id: member.id,
               approver_id: approver.id
             )

      refute Repo.get_by(Post.ApprovalRequest.Rejection,
               post_id: post_id,
               requester_id: member.id,
               approver_id: approver.id
             )
    end
  end

  describe "create business offer" do
    [{"owner", true}, {"admin", false}]
    |> Enum.each(fn {role, approved} ->
      test "when user is #{role}", %{conn: conn} do
        %{
          member: user,
          business_account:
            %{
              id: business_id,
              username: business_name
            } = business_account
        } = insert(:user_membership, role: unquote(role))

        %{media_key: media_key} = insert(:upload, owner: user)

        conn =
          conn
          |> authenticate(insert(:auth_token, user: user))
          |> post(Routes.post_path(conn, :create), %{
            "type" => "offer",
            "business_username" => business_account.username,
            "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
            "title" => "Business offer",
            "body" => "Description",
            "business_offer" => %{
              "discount" => "20%",
              "discount_code" => "SALE0001",
              "business_address" => "Broken Dreams blvd. 1",
              "qr_code" => "SALE0001",
              "bar_code" => "1234098765",
              "expires_at" => "2038-01-01 01:01:01Z"
            },
            "media_file_keys" => [media_key],
            "interests" => ["#hash", %{"hashtag" => "#hashtag"}]
          })
          |> doc()

        assert %{
                 "success" => true,
                 "result" => %{
                   "author" => %{
                     "id" => author_id
                   },
                   "body" => "Description",
                   "business" => %{"id" => ^business_id},
                   "business_admin" => %{"id" => ^business_id},
                   "business_name" => ^business_name,
                   "comments_count" => 0,
                   "downvotes_count" => 0,
                   "events" => [],
                   "fake_location?" => false,
                   "id" => post_id,
                   "inserted_at" => _,
                   "interests" => ["hash", "hashtag"],
                   "location" => %{
                     "coordinates" => [30.7008, 76.7885],
                     "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                     "type" => "Point"
                   },
                   "media_file_keys" => [
                     %{"results" => [%{"media_key" => ^media_key}]}
                   ],
                   "place" => nil,
                   "polls" => [],
                   "post_cost" => nil,
                   "private?" => false,
                   "title" => "Business offer",
                   "type" => "offer",
                   "updated_at" => _,
                   "upvotes_count" => 0,
                   "user_downvoted?" => false,
                   "user_upvoted?" => false,
                   "approved?" => unquote(approved)
                 }
               } = json_response(conn, 200)

        assert %{
                 type: "offer",
                 approved?: unquote(approved),
                 id: ^post_id,
                 business_id: ^business_id,
                 business: %{id: ^business_id, is_business: true},
                 business_offer: %{
                   post_id: ^post_id,
                   business_id: ^business_id,
                   discount: "20%",
                   discount_code: "SALE0001",
                   business_address: "Broken Dreams blvd. 1",
                   qr_code: "SALE0001",
                   bar_code: "1234098765",
                   expires_at: ~U[2038-01-01 01:01:01.000000Z]
                 },
                 interests: [
                   %{hashtag: "hash"},
                   %{hashtag: "hashtag"}
                 ],
                 media_files: [
                   %{media_key: ^media_key}
                 ]
               } =
                 Repo.get!(Post, post_id)
                 |> Repo.preload([
                   :interests,
                   :media_files,
                   :business,
                   :business_admin,
                   :business_offer
                 ])
      end
    end)

    test "by a regular user", %{conn: conn} do
      %{username: business_username} = insert(:business_account)
      user = insert(:user)

      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> post(Routes.post_path(conn, :create), %{
          "type" => "offer",
          "business_username" => business_username,
          "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
          "title" => "Business offer",
          "body" => "Description",
          "business_offer" => %{
            "discount_code" => "SALE0001",
            "business_address" => "Broken Dreams blvd. 1",
            "expires_at" => "2038-01-01 01:01:01Z"
          },
          "media_file_keys" => [],
          "interests" => []
        })

      assert %{
               "success" => false,
               "reason" => "Unauthorized to create post"
             } = json_response(conn, 403)
    end
  end

  describe "delete business offer" do
    test "succeeds by a business owner", %{conn: conn} do
      %{
        member: user,
        business_account: business_account
      } = insert(:user_membership, role: "owner")

      post = insert(:business_post, business_account: business_account)

      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> delete(Routes.post_path(conn, :delete, post.id, %{}))
        |> doc()

      assert "" = response(conn, 204)
      assert nil == Repo.get(Post, post.id)
    end

    test "succeeds by a business admin", %{conn: conn} do
      %{
        member: user,
        business_account: business_account
      } = insert(:user_membership, role: "admin")

      post = insert(:business_post, business_account: business_account)

      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> delete(Routes.post_path(conn, :delete, post.id, %{}))
        |> doc()

      assert "" = response(conn, 204)
      assert nil == Repo.get(Post, post.id)
    end

    test "succeeds by a business member who is the post's author", %{conn: conn} do
      %{
        member: user,
        business_account: business_account
      } = insert(:user_membership, role: "member")

      post = insert(:business_post, author: user, business_account: business_account)

      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> delete(Routes.post_path(conn, :delete, post.id, %{}))
        |> doc()

      assert "" = response(conn, 204)
      assert nil == Repo.get(Post, post.id)
    end

    test "fails by a business member who is not the post's author", %{conn: conn} do
      %{
        member: user,
        business_account: business_account
      } = insert(:user_membership, role: "member")

      post = insert(:business_post, business_account: business_account)

      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> delete(Routes.post_path(conn, :delete, post.id, %{}))
        |> doc()

      assert "" = response(conn, 403)
      assert %Post{} = Repo.get(Post, post.id)
    end

    test "fails by the post's author who is not a member", %{conn: conn} do
      user = insert(:user)
      post = insert(:business_post, author: user)

      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> delete(Routes.post_path(conn, :delete, post.id, %{}))
        |> doc()

      assert "" = response(conn, 403)
      assert %Post{} = Repo.get(Post, post.id)
    end

    test "fails by another user", %{conn: conn} do
      post = insert(:business_post)

      conn =
        conn
        |> authenticate(insert(:auth_token))
        |> delete(Routes.post_path(conn, :delete, post.id, %{}))
        |> doc()

      assert "" = response(conn, 403)
      assert %Post{} = Repo.get(Post, post.id)
    end
  end

  describe "update business offer" do
    setup do
      business_account = insert(:business_account)

      business_offer =
        build(:business_offer,
          business: business_account,
          discount: "25%",
          discount_code: "SALE0001",
          qr_code: "CODE0001",
          bar_code: "4321",
          expires_at: ~U[2038-01-01 01:01:01Z],
          post: nil
        )

      user = insert(:user)

      post =
        insert(:business_post,
          author: user,
          business_account: business_account,
          business_offer: business_offer
        )

      %{
        user: user,
        post: post,
        business_account: business_account,
        business_offer: business_offer
      }
    end

    test "succeeds when user is owner", %{
      conn: conn,
      business_account: %{id: business_id} = business_account,
      user: user,
      post: %{id: post_id} = post
    } do
      insert(:user_membership, member: user, business_account: business_account, role: "owner")

      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> put(Routes.post_path(conn, :update, post.id), %{
          "business_offer" => %{
            "discount" => "80%",
            "discount_code" => "SALE4321",
            "business_address" => "Broken Dreams blvd. 123",
            "qr_code" => "CODE4321",
            "bar_code" => "1234098765",
            "expires_at" => "2028-01-01 01:01:01Z"
          }
        })
        |> doc()

      assert %{
               "success" => true,
               "result" => %{"id" => ^post_id}
             } = json_response(conn, 200)

      assert %{
               type: "offer",
               approved?: true,
               id: ^post_id,
               business_id: ^business_id,
               business: %{id: ^business_id, is_business: true},
               business_offer: %{
                 post_id: ^post_id,
                 business_id: ^business_id,
                 discount: "80%",
                 discount_code: "SALE4321",
                 business_address: "Broken Dreams blvd. 123",
                 qr_code: "CODE4321",
                 bar_code: "1234098765",
                 expires_at: ~U[2028-01-01 01:01:01.000000Z]
               },
               interests: [],
               media_files: []
             } =
               Repo.get!(Post, post_id)
               |> Repo.preload([
                 :interests,
                 :media_files,
                 :business,
                 :business_admin,
                 :business_offer
               ])
    end

    test "fails when user is not a member and not the author", %{conn: conn, post: post} do
      conn =
        conn
        |> authenticate(insert(:auth_token))
        |> put(Routes.post_path(conn, :update, post.id), %{
          "business_offer" => %{"discount" => "80%"}
        })

      assert "" = response(conn, 403)
      assert %Post{} = Repo.get(Post, post.id)
    end
  end

  describe "show business offer" do
    setup do
      business_account = insert(:business_account)

      business_offer =
        build(:business_offer,
          business: business_account,
          discount: "25%",
          discount_code: "SALE0001",
          qr_code: "CODE0001",
          bar_code: "4321",
          expires_at: ~U[2038-01-01 01:01:01Z],
          post: nil
        )

      user = insert(:user)

      post =
        insert(:business_post,
          author: user,
          business_account: business_account,
          business_offer: business_offer
        )

      %{
        user: user,
        post: post,
        business_account: business_account,
        business_offer: business_offer
      }
    end

    test "returns complete post", %{
      conn: conn,
      business_account: %{id: business_id},
      user: %{id: user_id} = user,
      post: %{id: post_id} = post
    } do
      conn =
        conn
        |> authenticate(insert(:auth_token, user: user))
        |> get(Routes.post_path(conn, :show, post.id), %{
          "business_offer" => %{
            "discount" => "80%",
            "discount_code" => "SALE4321",
            "business_address" => "Broken Dreams blvd. 123",
            "qr_code" => "CODE4321",
            "bar_code" => "1234098765",
            "expires_at" => "2028-01-01 01:01:01Z"
          }
        })
        |> doc()

      assert %{
               "id" => ^post_id,
               "approved?" => true,
               "author" => %{
                 "id" => ^user_id
               },
               "business" => %{
                 "id" => ^business_id
               },
               "business_admin" => %{
                 "id" => ^business_id
               },
               "business_offer" => %{
                 "bar_code" => "4321",
                 "business_address" => nil,
                 "discount" => "25%",
                 "discount_code" => "SALE0001",
                 "expires_at" => "2038-01-01T01:01:01.000000Z",
                 "qr_code" => "CODE0001"
               }
             } = json_response(conn, 200)
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..10, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end

  describe "list_nearby" do
    setup do
      now = DateTime.utc_now()

      p1 =
        insert(:post,
          inserted_at: Timex.shift(now, minutes: -1),
          location: %BillBored.Geo.Point{lat: 51.23399, long: -0.138531}
        )

      p2 =
        insert(:post,
          type: "event",
          inserted_at: now,
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event, post: p2, date: Timex.shift(now, hours: -5))

      p3 =
        insert(:post,
          type: "event",
          inserted_at: now,
          location: %BillBored.Geo.Point{lat: 51.188059, long: -0.139366}
        )

      insert(:event, post: p3, date: Timex.shift(now, hours: 1))

      p4 =
        insert(:post,
          inserted_at: Timex.shift(now, minutes: -5),
          location: %BillBored.Geo.Point{lat: 51.117661, long: -0.161299}
        )

      p5 =
        insert(:post,
          type: "vote",
          inserted_at: now,
          location: %BillBored.Geo.Point{lat: 51.110635, long: -0.147783}
        )

      # private post shouldn't be returned or affect result in any way
      _p6 =
        insert(:post,
          type: "regular",
          inserted_at: now,
          location: %BillBored.Geo.Point{lat: 51.110635, long: -0.147783},
          private?: true
        )

      %{posts: [p1, p2, p3, p4, p5]}
    end

    test "returns posts with geohashes touching radius", %{
      conn: conn,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, %{id: p4_id}, %{id: p5_id}]
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5
               })
               |> json_response(200)

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p5_id},
                 %{"id" => ^p4_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.114084, -0.155488]},
                 "radius" => 3300,
                 "precision" => 5
               })
               |> json_response(200)

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p5_id},
                 %{"id" => ^p1_id},
                 %{"id" => ^p4_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.152344, -0.29315]},
                 "radius" => 1300,
                 "precision" => 4
               })
               |> doc()
               |> json_response(200)
    end

    test "allows pagination", %{
      conn: conn,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, _p4, _p5]
    } do
      conn = authenticate(conn, insert(:auth_token))

      params = %{
        "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
        "radius" => 800,
        "precision" => 5,
        "page_size" => 1
      }

      assert %{
               "page_number" => 1,
               "page_size" => 1,
               "entries" => [
                 %{"id" => ^p3_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), Map.merge(params, %{"page" => 1}))
               |> doc()
               |> json_response(200)

      assert %{
               "page_number" => 2,
               "page_size" => 1,
               "entries" => [
                 %{"id" => ^p2_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), Map.merge(params, %{"page" => 2}))
               |> json_response(200)

      assert %{
               "page_number" => 3,
               "page_size" => 1,
               "entries" => [
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), Map.merge(params, %{"page" => 3}))
               |> json_response(200)
    end

    test "allows filtering by types", %{
      conn: conn,
      posts: [_p1, %{id: p2_id}, %{id: p3_id}, _p4, %{id: p5_id}]
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p5_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.152344, -0.29315]},
                 "radius" => 1300,
                 "precision" => 4,
                 "types" => ["vote", "event"]
               })
               |> doc()
               |> json_response(200)
    end

    test "filters posts by keyword", %{
      conn: conn
    } do
      %{id: post_id} =
        post =
        insert(:post,
          type: "event",
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event, post: post, title: "Automated testing")

      conn = authenticate(conn, insert(:auth_token))
      filter = %{"keyword" => "test"}

      assert %{
               "entries" => [
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "filter" => filter
               })
               |> doc()
               |> json_response(200)
    end

    test "filters free events", %{
      conn: conn
    } do
      %{id: post_id} =
        post =
        insert(:post,
          type: "event",
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event, post: post, price: 0.0)

      conn = authenticate(conn, insert(:auth_token))
      filter = %{"show_free" => true}

      assert %{
               "entries" => [
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "filter" => filter
               })
               |> doc()
               |> json_response(200)
    end

    test "filters paid events", %{
      conn: conn
    } do
      %{id: post_id} =
        post =
        insert(:post,
          type: "event",
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event, post: post, price: 25.0, currency: "GBP")

      conn = authenticate(conn, insert(:auth_token))
      filter = %{"show_paid" => true}

      assert %{
               "entries" => [
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "filter" => filter
               })
               |> doc()
               |> json_response(200)
    end

    test "filters courses", %{
      conn: conn
    } do
      %{id: post_id} =
        post =
        insert(:post,
          type: "event",
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event, post: post, title: "Learn DevOps in 21 hours", price: 500.0, currency: "USD")

      conn = authenticate(conn, insert(:auth_token))
      filter = %{"show_courses" => true, "show_paid" => true}

      assert %{
               "entries" => [
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "filter" => filter
               })
               |> doc()
               |> json_response(200)
    end

    test "filters posts by event categories", %{
      conn: conn
    } do
      %{id: post_id} =
        post =
        insert(:post,
          type: "event",
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event, post: post, categories: ["jogging"])

      conn = authenticate(conn, insert(:auth_token))
      filter = %{"categories" => ["jogging"]}

      assert %{
               "entries" => [
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "filter" => filter
               })
               |> doc()
               |> json_response(200)
    end

    test "filters child friendly events", %{
      conn: conn
    } do
      %{id: post_id} =
        post =
        insert(:post,
          type: "event",
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event, post: post, child_friendly: true)

      conn = authenticate(conn, insert(:auth_token))
      filter = %{"show_child_friendly" => true}

      assert %{
               "entries" => [
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "filter" => filter
               })
               |> doc()
               |> json_response(200)
    end

    test "filters not child friendly events", %{
      conn: conn,
      posts: [_p1, %{id: p2_id}, %{id: p3_id}, _p4, _p5]
    } do
      %{id: post_id} =
        post =
        insert(:post,
          type: "event",
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      insert(:event,
        post: post,
        date: Timex.shift(DateTime.utc_now(), hours: -10),
        child_friendly: false
      )

      conn = authenticate(conn, insert(:auth_token))
      filter = %{"show_child_friendly" => false}

      assert %{
               "entries" => [
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "filter" => filter
               })
               |> json_response(200)
    end

    test "filters business posts", %{conn: conn} do
      business = insert(:business_account)

      %{id: post_id} =
        insert(:post,
          business_id: business.id,
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "entries" => [
                 %{"id" => ^post_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5,
                 "is_business" => true
               })
               |> json_response(200)
    end

    test "renders posts with all associations", %{
      conn: conn
    } do
      upload = insert(:upload, media_key: "abcd0123")

      %{id: post_id} = post = insert(:post, type: "event", media_files: [upload])
      insert(:event, post: post)
      insert(:post_interest, post: post, interest: insert(:interest, hashtag: "hash"))
      insert(:post_interest, post: post, interest: insert(:interest, hashtag: "mash"))

      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "entries" => [
                 %{
                   "id" => ^post_id,
                   "author" => author,
                   "events" => [event],
                   "interests" => ["hash", "mash"],
                   "media_file_keys" => [
                     %{
                       "results" => [
                         %{
                           "media_key" => "abcd0123"
                         }
                       ]
                     }
                   ]
                 } = result_post
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{
                   "type" => "Point",
                   "coordinates" => [post.location.lat, post.location.long]
                 },
                 "radius" => 800,
                 "precision" => 5
               })
               |> json_response(200)

      assert Map.keys(author) |> Enum.sort() == [
               "avatar",
               "avatar_thumbnail",
               "first_name",
               "id",
               "is_ghost",
               "last_name",
               "username"
             ]

      assert Map.keys(event) |> Enum.sort() == [
               "accepted_count",
               "attendees",
               "buy_ticket_link",
               "categories",
               "child_friendly",
               "currency",
               "date",
               "doubts_count",
               "id",
               "inserted_at",
               "invited_count",
               "location",
               "media_file_keys",
               "missed_count",
               "other_date",
               "place",
               "presented_count",
               "price",
               "refused_count",
               "title",
               "universal_link",
               "updated_at",
               "user_attending?",
               "user_status"
             ]
    end

    test "returns correct social counters", %{
      conn: conn
    } do
      user = insert(:user)

      %{id: post_id} = post = insert(:post)

      insert_list(2, :post_upvote, post: post)
      insert_list(2, :post_downvote, post: post)
      insert(:post_downvote, post: post, user: user)
      insert_list(5, :post_comment, post: post)

      conn = authenticate(conn, insert(:auth_token, user: user))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{
                   "id" => ^post_id,
                   "upvotes_count" => 2,
                   "downvotes_count" => 3,
                   "comments_count" => 5,
                   "user_upvoted?" => false,
                   "user_downvoted?" => true
                 }
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{
                   "type" => "Point",
                   "coordinates" => [post.location.lat, post.location.long]
                 },
                 "radius" => 800,
                 "precision" => 5
               })
               |> json_response(200)
    end

    test "does not return blocked user's posts", %{
      conn: conn
    } do
      user = insert(:user)

      %{id: post_id} = post = insert(:post)

      blocked_post = insert(:post)
      insert(:user_block, blocker: user, blocked: blocked_post.author)

      conn = authenticate(conn, insert(:auth_token, user: user))

      assert %{
               "entries" => [%{"id" => ^post_id}],
               "page_number" => 1,
               "page_size" => 30
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{
                   "type" => "Point",
                   "coordinates" => [post.location.lat, post.location.long]
                 },
                 "radius" => 800,
                 "precision" => 5
               })
               |> json_response(200)
    end

    test "does not return posts if author blocked current user", %{
      conn: conn
    } do
      user = insert(:user)

      %{id: post_id} = post = insert(:post)

      blocker_post = insert(:post)
      insert(:user_block, blocker: blocker_post.author, blocked: user)

      conn = authenticate(conn, insert(:auth_token, user: user))

      assert %{
               "entries" => [%{"id" => ^post_id}],
               "page_number" => 1,
               "page_size" => 30
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "location" => %{
                   "type" => "Point",
                   "coordinates" => [post.location.lat, post.location.long]
                 },
                 "radius" => 800,
                 "precision" => 5
               })
               |> json_response(200)
    end
  end

  describe "list_nearby offers" do
    setup do
      now = DateTime.utc_now()

      p1 =
        insert(:business_post,
          inserted_at: Timex.shift(now, minutes: -5),
          business_offer:
            build(:business_offer,
              post: nil,
              business_address: "Address",
              discount: "80%",
              discount_code: "SALE0001",
              qr_code: "CODE0001",
              bar_code: "1234098765",
              expires_at: ~U[2038-01-01 01:01:01Z]
            ),
          location: %BillBored.Geo.Point{lat: 51.23399, long: -0.138531}
        )

      p2 =
        insert(:business_post,
          inserted_at: now,
          business_offer:
            build(:business_offer, post: nil, expires_at: Timex.shift(now, days: 1)),
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      p3 =
        insert(:business_post,
          inserted_at: now,
          business_offer:
            build(:business_offer, post: nil, expires_at: Timex.shift(now, minutes: 5)),
          location: %BillBored.Geo.Point{lat: 51.172073, long: -0.164037}
        )

      %{posts: [p1, p2, p3]}
    end

    test "returns business posts in correct order", %{
      conn: conn,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}]
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "types" => ["offer"],
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5
               })
               |> json_response(200)
    end

    test "returns post's business offer", %{
      conn: conn,
      posts: [%{id: p1_id}, _p2, _p3]
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "page_number" => 3,
               "page_size" => 1,
               "entries" => [p1_result]
             } =
               conn
               |> post(Routes.post_path(conn, :list_nearby), %{
                 "types" => ["offer"],
                 "page_size" => 1,
                 "page" => 3,
                 "location" => %{"type" => "Point", "coordinates" => [51.196289, -0.131836]},
                 "radius" => 800,
                 "precision" => 5
               })
               |> json_response(200)

      assert %{
               "id" => ^p1_id,
               "business_offer" => %{
                 "business_address" => "Address",
                 "discount" => "80%",
                 "discount_code" => "SALE0001",
                 "qr_code" => "CODE0001",
                 "bar_code" => "1234098765",
                 "expires_at" => "2038-01-01T01:01:01.000000Z"
               }
             } = p1_result
    end
  end

  describe "list_business_posts" do
    setup do
      now = DateTime.utc_now()
      business = insert(:business_account)

      owner = insert(:user)
      insert(:user_membership, business_account: business, member: owner, role: "owner")

      admin = insert(:user)
      insert(:user_membership, business_account: business, member: admin, role: "admin")

      member = insert(:user)
      insert(:user_membership, business_account: business, member: member, role: "member")

      p1 =
        insert(:business_post,
          business_account: business,
          author: owner,
          inserted_at: Timex.shift(now, days: -1)
        )

      p2 =
        insert(:business_post,
          business_account: business,
          type: "event",
          author: admin,
          inserted_at: Timex.shift(now, minutes: -15)
        )

      p3 =
        insert(:business_post,
          business_account: business,
          type: "poll",
          author: member,
          inserted_at: Timex.shift(now, minutes: -1)
        )

      p4 =
        insert(:business_post,
          business_account: business,
          type: "poll",
          author: member,
          inserted_at: now,
          approved?: false
        )

      # private post shouldn't be returned or affect result in any way
      _p4 = insert(:business_post, type: "regular", inserted_at: now, private?: true)

      %{business: business, owner: owner, admin: admin, member: member, posts: [p1, p2, p3, p4]}
    end

    test "returns approved posts in correct order", %{
      conn: conn,
      business: business,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, _p4]
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p1_id} = p1_body
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{})
               |> doc()
               |> json_response(200)
    end

    test "owner can list unapproved posts", %{
      conn: conn,
      owner: owner,
      business: business,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, %{id: p4_id}]
    } do
      conn = authenticate(conn, insert(:auth_token, user: owner))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p4_id},
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "include_unapproved" => true
               })
               |> json_response(200)
    end

    test "admin can list unapproved posts", %{
      conn: conn,
      admin: admin,
      business: business,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, %{id: p4_id}]
    } do
      conn = authenticate(conn, insert(:auth_token, user: admin))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p4_id},
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "include_unapproved" => true
               })
               |> json_response(200)
    end

    test "member can list their own unapproved posts", %{
      conn: conn,
      member: member,
      business: business,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, %{id: p4_id}]
    } do
      conn = authenticate(conn, insert(:auth_token, user: member))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p4_id},
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "include_unapproved" => true
               })
               |> json_response(200)
    end

    test "member can't list other member's unapproved posts", %{
      conn: conn,
      business: business,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, _p4]
    } do
      another_member = insert(:user)
      insert(:user_membership, business_account: business, member: another_member, role: "member")
      conn = authenticate(conn, insert(:auth_token, user: another_member))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p3_id},
                 %{"id" => ^p2_id},
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "include_unapproved" => true
               })
               |> json_response(200)
    end

    test "unprivileged user can't list unapproved posts", %{
      conn: conn,
      business: business
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "error" => "insufficient_privileges",
               "reason" => "insufficient_privileges",
               "success" => false
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "include_unapproved" => true
               })
               |> json_response(422)
    end

    test "allows pagination", %{
      conn: conn,
      business: business,
      posts: [%{id: p1_id}, %{id: p2_id}, %{id: p3_id}, _p4]
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "page_number" => 1,
               "page_size" => 1,
               "entries" => [
                 %{"id" => ^p3_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "page_size" => 1,
                 "page" => 1
               })
               |> doc()
               |> json_response(200)

      assert %{
               "page_number" => 2,
               "page_size" => 1,
               "entries" => [
                 %{"id" => ^p2_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "page_size" => 1,
                 "page" => 2
               })
               |> json_response(200)

      assert %{
               "page_number" => 3,
               "page_size" => 1,
               "entries" => [
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "page_size" => 1,
                 "page" => 3
               })
               |> json_response(200)
    end

    test "allows filtering by types", %{
      conn: conn,
      business: business,
      posts: [%{id: p1_id}, _p2, _p3, _p4]
    } do
      conn = authenticate(conn, insert(:auth_token))

      assert %{
               "page_number" => 1,
               "page_size" => 30,
               "entries" => [
                 %{"id" => ^p1_id}
               ]
             } =
               conn
               |> get(Routes.post_path(conn, :list_business_posts, business.id), %{
                 "types" => ["offer"]
               })
               |> doc()
               |> json_response(200)
    end
  end
end
