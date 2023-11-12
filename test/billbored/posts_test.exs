defmodule BillBored.PostsTest do
  use BillBored.DataCase, async: true
  import Assertions
  alias BillBored.{User, Post, Posts, Interest, Event}

  @attrs %{
    "type" => "regular",
    "title" => "  Etherstrhrth ",
    "media_file_keys" => [],
    "body" => "Rthrthrthrth ",
    "location" => [30.7008, 76.7885],
    "interests" => [
      %{"hashtag" => "#one"},
      %{"hashtag" => "##two"},
      "#one #and two",
      %{"hashtag" => "##четыре#  #  -- #"}
    ],
    "private?" => false
    #        "fake?" => false
  }

  describe "post" do
    test "get" do
      lovers = for _ <- 1..4, do: insert(:user)
      haters = for _ <- 1..6, do: insert(:user)
      neutral = insert(:user)

      for _ <- 1..5 do
        post = insert(:post)
        post = Posts.get!(post.id, for: neutral)

        assert post.comments_count == 0
        assert post.downvotes_count == 0
        assert post.upvotes_count == 0

        refute post.user_upvoted?
        refute post.user_downvoted?

        #

        for downvoter <- haters do
          insert(:post_downvote, post: post, user: downvoter)
        end

        for upvoter <- lovers do
          insert(:post_upvote, post: post, user: upvoter)
        end

        for _ <- 1..10 do
          insert(:post_comment, post: post)
        end

        for lover <- lovers do
          post = Posts.get!(post.id, for: lover)

          assert post.user_upvoted?
          refute post.user_downvoted?

          assert post.comments_count == 10
          assert post.upvotes_count == 4
          assert post.downvotes_count == 6
        end

        for hater <- haters do
          post = Posts.get!(post.id, for: hater)

          assert post.user_downvoted?
          refute post.user_upvoted?

          assert post.comments_count == 10
          assert post.upvotes_count == 4
          assert post.downvotes_count == 6
        end

        # neutral

        post = Posts.get!(post.id, for: neutral)

        refute post.user_downvoted?
        refute post.user_upvoted?

        assert post.comments_count == 10
        assert post.upvotes_count == 4
        assert post.downvotes_count == 6
      end
    end

    test "get!/1 does not return hidden posts" do
      post = insert(:post, hidden?: true)

      assert_raise Ecto.NoResultsError, fn ->
        Posts.get!(post.id)
      end
    end

    test "index" do
      author = insert(:user)

      lovers = for _ <- 1..4, do: insert(:user)
      haters = for _ <- 1..6, do: insert(:user)

      for _ <- 1..25 do
        post = insert(:post, author: author)

        for downvoter <- haters do
          insert(:post_downvote, post: post, user: downvoter)
        end

        for upvoter <- lovers do
          insert(:post_upvote, post: post, user: upvoter)
        end

        for _ <- 1..10 do
          insert(:post_comment, post: post)
        end
      end

      # upvoter:

      #
      index = Posts.index(author.id, %{for: hd(lovers)})

      assert index.total_entries == 25
      assert index.page_number == 1
      assert index.total_pages == 3
      assert Enum.count(index.entries, & &1.user_upvoted?) == 10
      assert Enum.count(index.entries, & &1.user_downvoted?) == 0
      assert Enum.all?(index.entries, &(&1.upvotes_count == 4))
      assert Enum.all?(index.entries, &(&1.downvotes_count == 6))

      #
      index = Posts.index(author.id, %{for: hd(lovers), page: 2})

      assert index.page_number == 2
      assert Enum.count(index.entries, & &1.user_upvoted?)

      # downvoter:

      #
      index = Posts.index(author.id, %{for: hd(haters)})

      assert Enum.count(index.entries, & &1.user_upvoted?) == 0
      assert Enum.count(index.entries, & &1.user_downvoted?) == 10
      assert Enum.all?(index.entries, &(&1.upvotes_count == 4))
      assert Enum.all?(index.entries, &(&1.downvotes_count == 6))
    end

    test "returns recently updated posts first" do
      author = insert(:user)
      %{id: p1_id} = insert(:post, inserted_at: ~U[2020-02-02T05:00:00Z], updated_at: ~U[2020-02-02T05:00:00Z], author: author)
      %{id: p2_id} = insert(:post, inserted_at: ~U[2020-02-02T10:00:00Z], updated_at: ~U[2020-02-02T10:00:00Z], author: author)
      %{id: p3_id} = insert(:post, inserted_at: ~U[2020-02-02T09:55:00Z], updated_at: ~U[2020-02-02T11:00:00Z], author: author)

      assert %{
        total_pages: 1,
        total_entries: 3,
        entries: [%{id: ^p3_id}, %{id: ^p2_id}, %{id: ^p1_id}]
      } = Posts.index(author.id, %{})
    end

    test "index for blocked" do
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)

      insert_list(5, :post, author: user1)
      insert_list(3, :post, author: user2)
      user3_posts = insert_list(2, :post, author: user3)

      insert(:user_block, blocker: user1, blocked: user2)

      assert %Scrivener.Page{entries: []} = Posts.index(user2.id, %{for: user1})
      assert %Scrivener.Page{entries: entries1} = Posts.index(user3.id, %{for: user1})
      assert sorted_ids(entries1) == sorted_ids(user3_posts)

      assert %Scrivener.Page{entries: []} = Posts.index(user1.id, %{for: user2})
      assert %Scrivener.Page{entries: entries2} = Posts.index(user3.id, %{for: user2})
      assert sorted_ids(entries2) == sorted_ids(user3_posts)
    end

    test "index/1 does not return hidden posts" do
      author = insert(:user)
      %{id: post_id} = insert(:post, author: author)
      insert(:post, author: author, hidden?: true)

      assert %Scrivener.Page{entries: [%{id: ^post_id}]} = Posts.index(author.id, %{})
    end

    test "index/1 does not return posts of banned users" do
      author = insert(:user, banned?: true)
      insert(:post, author: author)

      assert %Scrivener.Page{entries: []} = Posts.index(author.id, %{})
    end

    test "create" do
      author = insert(:user)

      attrs = Map.put(@attrs, "author_id", author.id)
      {:ok, post} = Posts.insert_or_update(%Post{}, attrs)

      refute post.fake_location
      assert post.title == String.trim(attrs["title"])

      [one, two, one_and_two, four] = Repo.all(Interest)
      assert [one, two, one_and_two, four] == Repo.preload(post, [:interests]).interests

      assert one.hashtag == "one"
      assert two.hashtag == "two"
      assert one_and_two.hashtag == "one-and-two"
      assert four.hashtag == "четыре"

      attrs = %{attrs | "interests" => ["one", "two", "five"]}
      {:ok, post} = Posts.insert_or_update(%Post{}, attrs)

      assert Enum.map(Repo.all(Interest), & &1.hashtag) == [
               "one",
               "two",
               "one-and-two",
               "четыре",
               "five"
             ]

      post_interests = Repo.preload(post, [:interests]).interests
      assert length(post_interests) == 3

      #

      attrs = %{attrs | "interests" => ["#n", "w", ""]}
      {:error, changeset} = Posts.insert_or_update(%Post{}, attrs)

      refute changeset.valid?

      err =
        {"hashtag \"n\" could not be added: should be at least 2 character(s); hashtag \"w\" could not be added: should be at least 2 character(s)",
         []}

      assert changeset.errors[:interests] == err

      #

      attrs = %{attrs | "type" => "wrong-type", "interests" => []}
      {:error, changeset} = Posts.insert_or_update(%Post{}, attrs)

      err = {"is invalid", [validation: :inclusion, enum: ["vote", "poll", "regular", "event", "offer"]]}
      refute changeset.valid?
      assert changeset.errors[:type] == err

      # "type": "poll"
      attrs = %{attrs | "type" => "poll", "interests" => []}
      {:error, changeset} = Posts.insert_or_update(%Post{}, attrs)

      refute changeset.valid?
      assert changeset.errors[:polls]
    end

    test "create with polls" do
      author = insert(:user)

      attrs =
        @attrs
        |> Map.put("author_id", author.id)
        |> Map.put("polls", [
          %{
            "question" => "Are you alive?",
            "items" => [
              "Yes!",
              %{"title" => "No!", "media_file_keys" => []}
            ]
          }
        ])

      {:ok, post} = Posts.insert_or_update(%Post{}, attrs)

      assert length(post.polls) == 1

      #
      attrs = %{
        attrs
        | "polls" => [
            %{
              "question" => "Are you alive?",
              "items" => [
                %{"title" => ""},
                %{"title" => "No!", "media_file_keys" => []}
              ]
            }
          ]
      }

      assert {:error, _changeset} = Posts.insert_or_update(%Post{}, attrs)
    end
  end

  describe "update" do
    def insert_post_for_update(params \\ []) do
      %{id: post_id} = insert(:post, params)
      Posts.get!(post_id)
    end

    def post_attrs(post, changes) do
      %{
        "id" => post.id,
        "type" => post.type,
        "location" => [post.location.long, post.location.lat],
        "author_id" => post.author_id
      }
      |> Map.merge(changes)
    end

    test "resets review_status when title changes" do
      %{id: post_id} = post = insert_post_for_update(review_status: "accepted")

      {:ok, %{id: ^post_id, review_status: nil}} =
        Posts.insert_or_update(post, post_attrs(post, %{"title" => "new title"}))
    end

    test "resets review_status when body changes" do
      %{id: post_id} = post = insert_post_for_update(review_status: "accepted")

      {:ok, %{id: ^post_id, review_status: nil}} =
        Posts.insert_or_update(post, post_attrs(post, %{"body" => "new body"}))
    end

    test "resets review_status when media files change" do
      %{id: post_id} = post = insert_post_for_update(review_status: "accepted")
      upload = insert(:upload)

      {:ok, %{id: ^post_id, review_status: nil}} =
        Posts.insert_or_update(post, post_attrs(post, %{"media_file_keys" => [upload.media_key]}))
    end

    test "does not reset review_status when location changes" do
      %{id: post_id} = post = insert_post_for_update(review_status: "accepted")

      {:ok, %{id: ^post_id, review_status: "accepted"}} =
        Posts.insert_or_update(post, post_attrs(post, %{"location" => [30.30, 76.78]}))
    end
  end

  describe "search" do
    setup :create_posts

    test "point", %{posts: [post1, post2, _post3, _post4]} do
      %Scrivener.Page{entries: [%Post{} = found_post1, %Post{} = found_post2]} =
        Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 10000})

      assert Enum.sort([found_post1.id, found_post2.id]) == Enum.sort([post1.id, post2.id])
    end

    test "polygon", %{posts: [post1, post2, _post3, _post4]} do
      %Scrivener.Page{entries: [%Post{} = found_post1, %Post{} = found_post2]} =
        Posts.list_by_location(%BillBored.Geo.Polygon{
          coords: [
            %BillBored.Geo.Point{lat: 40.0, long: -49.0},
            %BillBored.Geo.Point{lat: 40.0, long: -55.0},
            %BillBored.Geo.Point{lat: 50.7, long: -55.0},
            %BillBored.Geo.Point{lat: 50.7, long: -49.0},
            %BillBored.Geo.Point{lat: 40.0, long: -49.0}
          ]
        })

      assert Enum.sort([found_post1.id, found_post2.id]) == Enum.sort([post1.id, post2.id])
    end

    test "with events", %{posts: [p1, p2, _p3, p4]} do
      insert(:event,
        post: p4,
        date: DateTime.utc_now(),
        other_date: DateTime.utc_now()
      )

      %Scrivener.Page{entries: [%Post{}, %Post{}, %Post{}] = posts} =
        Posts.list_by_location(%BillBored.Geo.Polygon{
          coords: [
            %BillBored.Geo.Point{lat: 40.0, long: -49.0},
            %BillBored.Geo.Point{lat: 40.0, long: -55.0},
            %BillBored.Geo.Point{lat: 50.7, long: -55.0},
            %BillBored.Geo.Point{lat: 50.7, long: -49.0},
            %BillBored.Geo.Point{lat: 40.0, long: -49.0}
          ]
        })

      posts
      |> Enum.map(& &1.id)
      |> assert_lists_equal([p1.id, p2.id, p4.id])

      %Scrivener.Page{
        entries: [_],
        page_number: 2,
        page_size: 1,
        total_entries: 3,
        total_pages: 3
      } =
        Posts.list_by_location(
          %BillBored.Geo.Polygon{
            coords: [
              %BillBored.Geo.Point{lat: 40.0, long: -49.0},
              %BillBored.Geo.Point{lat: 40.0, long: -55.0},
              %BillBored.Geo.Point{lat: 50.7, long: -55.0},
              %BillBored.Geo.Point{lat: 50.7, long: -49.0},
              %BillBored.Geo.Point{lat: 40.0, long: -49.0}
            ]
          },
          [],
          page: 2,
          page_size: 1
        )
    end
  end

  describe "posts/events ordering" do
    setup do
      {:ok, now: DateTime.utc_now(), location: %BillBored.Geo.Point{lat: 40.5, long: -50.0}}
    end

    test "posts are ordered by inserted_at closest to current date", %{
      now: now,
      location: location
    } do
      [p1, p2, p3, p4, p5] = [
        insert(:post, inserted_at: add_hours(now, 10), location: location),
        insert(:post, inserted_at: add_hours(now, -15), location: location),
        insert(:post, inserted_at: now, location: location),
        insert(:post, inserted_at: add_hours(now, -2), location: location),
        insert(:post, inserted_at: add_hours(now, 1), location: location)
      ]

      %Scrivener.Page{entries: ordered_posts} =
        Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 1000})

      assert Enum.map(ordered_posts, & &1.id) == Enum.map([p3, p5, p4, p1, p2], & &1.id)
    end

    test "events are ordered by begin_date closes to current date", %{
      now: now,
      location: location
    } do
      [e1, e2, e3, e4, e5] = [
        insert(:event, date: add_hours(now, 10), post: build(:post, location: location)),
        insert(:event, date: add_hours(now, -15), post: build(:post, location: location)),
        insert(:event, date: now, post: build(:post, location: location)),
        insert(:event, date: add_hours(now, -2), post: build(:post, location: location)),
        insert(:event, date: add_hours(now, 1), post: build(:post, location: location))
      ]

      %Scrivener.Page{entries: ordered_posts} =
        Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 1000})

      assert Enum.map(ordered_posts, & &1.id) == Enum.map([e3, e5, e4, e1, e2], & &1.post.id)
    end

    test "posts and events are ordered together", %{now: now, location: location} do
      [p1, p2, p3] = [
        insert(:post, inserted_at: add_hours(now, 10), location: location),
        insert(:post, inserted_at: add_hours(now, -15), location: location),
        insert(:post, inserted_at: add_hours(now, 1), location: location)
      ]

      [e1, e2, e3] = [
        insert(:event, date: now, post: build(:post, location: location)),
        insert(:event, date: add_hours(now, -2), post: build(:post, location: location)),
        insert(:event, date: add_hours(now, 1), post: build(:post, location: location))
      ]

      %Scrivener.Page{entries: ordered_posts} =
        Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 1000})

      assert Enum.map(ordered_posts, & &1.id) ==
               Enum.map([e1, e3, e2, p3, p1, p2], fn
                 %Post{id: id} -> id
                 %Event{post: %Post{id: id}} -> id
               end)
    end
  end

  describe "event filters" do
    test "with dates filter" do
      e1 =
        insert(:event,
          date: DateTime.utc_now(),
          other_date: DateTime.add(DateTime.utc_now(), 24 * 3600)
        )

      e2 =
        insert(:event,
          date: DateTime.add(DateTime.utc_now(), -2 * 24 * 3600),
          other_date: DateTime.add(DateTime.utc_now(), 4 * 24 * 3600)
        )

      e3 =
        insert(:event,
          date: DateTime.add(DateTime.utc_now(), 2 * 24 * 3600),
          other_date: DateTime.add(DateTime.utc_now(), 5 * 24 * 3600)
        )

      today = DateTime.utc_now()

      assert %Scrivener.Page{entries: [post1, post2]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{dates: [today]}
               )

      assert Enum.sort([post1.id, post2.id]) == Enum.sort([e1.post.id, e2.post.id])

      two_day_span = [
        DateTime.add(DateTime.utc_now(), 2 * 24 * 3600),
        DateTime.add(DateTime.utc_now(), 4 * 24 * 3600)
      ]

      assert %Scrivener.Page{entries: [post1, post2]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{dates: two_day_span}
               )

      assert Enum.sort([post1.id, post2.id]) == Enum.sort([e2.post.id, e3.post.id])
    end

    test "with free filter" do
      %{post: p1} = insert(:event, price: 0)
      insert(:event)
      %{post: p2} = insert(:event, price: 10.0)

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_free: true}
               )

      assert post.id == p1.id

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_free: false}
               )

      assert post.id == p2.id

      assert %Scrivener.Page{entries: [_, _, _]} =
               Posts.list_by_location({%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000})
    end

    test "with paid filter" do
      %{post: p1} = insert(:event, price: 0)
      insert(:event)
      %{post: p2} = insert(:event, price: 10.0)

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_paid: false}
               )

      assert post.id == p1.id

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_paid: true}
               )

      assert post.id == p2.id

      assert %Scrivener.Page{entries: [_, _, _]} =
               Posts.list_by_location({%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000})
    end

    test "with courses filter" do
      %{post: _p1} = insert(:event, post: build(:post, title: "free devops"))
      %{post: _p2} = insert(:event, post: build(:post, title: "paid sport"), price: 250.00)
      %{post: _p3} = insert(:event, post: build(:post, title: "paid course"), price: 201.00)

      assert %Scrivener.Page{entries: [_, _] = posts} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_courses: false}
               )

      posts
      |> Enum.map(& &1.title)
      |> assert_lists_equal(["paid sport", "free devops"])

      assert %Scrivener.Page{entries: [_, _] = posts} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{}
               )

      posts
      |> Enum.map(& &1.title)
      |> assert_lists_equal(["paid sport", "free devops"])

      assert %Scrivener.Page{entries: [_, _, _]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_courses: true}
               )
    end

    test "with child friendly filter" do
      %{post: p1} = insert(:event, child_friendly: true)
      %{post: p2} = insert(:event)
      %{post: p3} = insert(:event, child_friendly: false)

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_child_friendly: true}
               )

      assert post.id == p1.id

      assert %Scrivener.Page{entries: [post1, post2]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_child_friendly: false}
               )

      assert post1.id == p2.id
      assert post2.id == p3.id

      assert %Scrivener.Page{entries: [_, _, _]} =
               Posts.list_by_location({%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000})
    end

    test "with categories filter" do
      %{post: p1} = insert(:event, categories: ["music", "film"])
      insert(:event)
      %{post: p2} = insert(:event, categories: ["film", "nice"])

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{categories: ["music"]}
               )

      assert post.id == p1.id

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{categories: ["nice", "yeah"]}
               )

      assert post.id == p2.id

      assert %Scrivener.Page{entries: posts} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{categories: ["film", "nice"]}
               )

      assert posts |> Enum.map(& &1.id) |> Enum.sort() == [p1.id, p2.id]
    end

    test "with keyword filter" do
      %{post: p1} = insert(:event, title: "some music")
      insert(:event)
      %{post: p2} = insert(:event, title: "some film ok")

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{keyword: "music"}
               )

      assert post.id == p1.id

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{keyword: "film"}
               )

      assert post.id == p2.id

      assert %Scrivener.Page{entries: posts} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{keyword: "some"}
               )

      assert posts |> Enum.map(& &1.id) |> Enum.sort() == [p1.id, p2.id]
    end
  end

  describe "exclusion for blocked user" do
    test "point for blocked user", context do
      {:ok, posts: [post1, post2, _post3, _post4]} = create_posts(context)
      block1 = insert(:user_block, blocker: post2.author)

      assert %Scrivener.Page{entries: [%Post{id: found_post_id}]} =
               Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 10000},
                 for: block1.blocked
               )

      assert ^found_post_id = post1.id

      block2 = insert(:user_block, blocked: post1.author)

      assert %Scrivener.Page{entries: [%Post{id: found_post_id}]} =
               Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 10000},
                 for: block2.blocker
               )

      assert ^found_post_id = post2.id
    end

    test "with paid filter for blocked user" do
      %{post: p1} = insert(:event, price: 10.0)
      %{post: p2} = insert(:event, price: 30.0)

      block1 = insert(:user_block, blocker: p1.author)

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_paid: true, for: block1.blocked}
               )

      assert post.id == p2.id

      block2 = insert(:user_block, blocked: p2.author)

      assert %Scrivener.Page{entries: [post]} =
               Posts.list_by_location(
                 {%BillBored.Geo.Point{lat: 50.0, long: 50.0}, 1000},
                 %{show_paid: true, for: block2.blocker}
               )

      assert post.id == p1.id
    end
  end

  describe "exclusion for hidden posts" do
    test "point for hidden post", context do
      {:ok, posts: [%{id: p1_id} = _post1, post2, _post3, _post4]} = create_posts(context)

      from(p in Post, where: p.id == ^post2.id, update: [set: [hidden?: true]])
      |> Repo.update_all([])

      assert %Scrivener.Page{entries: [%Post{id: ^p1_id}]} =
               Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 10000})
    end
  end

  describe "exclusion for banned user's posts" do
    test "point for hidden post", context do
      {:ok, posts: [%{id: p1_id} = _post1, post2, _post3, _post4]} = create_posts(context)

      from(u in User, where: u.id == ^post2.author_id, update: [set: [banned?: true]])
      |> Repo.update_all([])

      assert %Scrivener.Page{entries: [%Post{id: ^p1_id}]} =
               Posts.list_by_location({%BillBored.Geo.Point{lat: 40.5, long: -50.0}, 10000})
    end
  end

  describe "list_markers/2 with smaller radius" do
    setup do
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

      # p4 and p5 are in the same geohash of length 5
      p4 = insert(:post, inserted_at: Timex.shift(now, minutes: -5), location: %BillBored.Geo.Point{lat: 51.117661, long: -0.161299})
      p5 = insert(:post, type: "vote", inserted_at: now, location: %BillBored.Geo.Point{lat: 51.110635, long: -0.147783})

      %{location: location, radius: radius, posts: [p1, p2, p3, p4, p5]}
    end

    test "returns clustered post markers", %{location: location, radius: radius, posts: [p1, p2, p3, p4, p5]} do
      # Marker's location is the averaged locations of all posts within common geohash
      # Top 3 posts are returned for each marker sorted by event.date ASC, inserted_at ASC

      markers = Posts.list_markers({location, radius})
      assert [m1, m2, m3] = Enum.sort_by(markers, & &1[:location])

      fields = [:id, :body, :title, :type]

      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.114148, long: -0.15454099999999998},
        posts_count: 2,
        top_posts: m1_posts
      } = m1

      assert m1_posts |> Enum.count() == 2
      assert m1_posts |> Enum.at(0) |> Map.take(fields) == Map.take(p5, fields)
      assert m1_posts |> Enum.at(1) |> Map.take(fields) == Map.take(p4, fields)

      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.180066, long: -0.1517015},
        posts_count: 2,
        top_posts: m2_posts
      } = m2

      assert m2_posts |> Enum.count() == 2
      assert m2_posts |> Enum.at(0) |> Map.take(fields) == Map.take(p3, fields)
      assert m2_posts |> Enum.at(1) |> Map.take(fields) == Map.take(p2, fields)

      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.23399, long: -0.138531},
        posts_count: 1,
        top_posts: m3_posts
      } = m3

      assert m3_posts |> Enum.count() == 1
      assert m3_posts |> Enum.at(0) |> Map.take(fields) == Map.take(p1, fields)
    end

    test "returns upto 3 posts for single geohash", %{location: location, radius: radius, posts: [p1, p2, p3, p4, p5]} do
      p6 = insert(:post, location: p3.location, inserted_at: Timex.shift(Timex.now, hours: -2))
      p7 = insert(:post, location: p5.location, inserted_at: Timex.shift(Timex.now, hours: -2))

      insert_list(3, :post, location: p3.location, inserted_at: Timex.shift(Timex.now, hours: -3))
      insert_list(3, :post, location: p5.location, inserted_at: Timex.shift(Timex.now, hours: -3))

      markers = Posts.list_markers({location, radius})
      assert [m1, m2, m3] = Enum.sort_by(markers, & &1[:location])

      fields = [:id, :body, :title, :type]

      assert m1[:location] == %BillBored.Geo.Point{lat: 51.111806, long: -0.15003566666666665}
      assert m1[:posts_count] == 6
      assert m1[:top_posts] |> Enum.count() == 3
      assert m1[:top_posts] |> Enum.at(0) |> Map.take(fields) == Map.take(p5, fields)
      assert m1[:top_posts] |> Enum.at(1) |> Map.take(fields) == Map.take(p4, fields)
      assert m1[:top_posts] |> Enum.at(2) |> Map.take(fields) == Map.take(p7, fields)

      assert m2[:location] == %BillBored.Geo.Point{lat: 51.18539466666667, long: -0.14347783333333333}
      assert m2[:posts_count] == 6
      assert m2[:top_posts] |> Enum.count() == 3
      assert m2[:top_posts] |> Enum.at(0) |> Map.take(fields) == Map.take(p3, fields)
      assert m2[:top_posts] |> Enum.at(1) |> Map.take(fields) == Map.take(p2, fields)
      assert m2[:top_posts] |> Enum.at(2) |> Map.take(fields) == Map.take(p6, fields)

      assert m3[:location] == %BillBored.Geo.Point{lat: 51.23399, long: -0.138531}
      assert m3[:posts_count] == 1
      assert m3[:top_posts] |> Enum.count() == 1
      assert m3[:top_posts] |> Enum.at(0) |> Map.take(fields) == Map.take(p1, fields)
    end

    test "selects only recent posts", %{location: location, radius: radius, posts: [_p1, _p2, _p3, p4, p5]} do
      insert_list(4, :post, location: p5.location, inserted_at: Timex.shift(Timex.now, days: -2))

      markers = Posts.list_markers({location, radius})
      assert [m1, _m2, _m3] = Enum.sort_by(markers, & &1[:location])

      fields = [:id, :body, :title, :type]

      assert m1[:location] == %BillBored.Geo.Point{lat: 51.114148, long: -0.15454099999999998}
      assert m1[:posts_count] == 2
      assert m1[:top_posts] |> Enum.count() == 2
      assert m1[:top_posts] |> Enum.at(0) |> Map.take(fields) == Map.take(p5, fields)
      assert m1[:top_posts] |> Enum.at(1) |> Map.take(fields) == Map.take(p4, fields)
    end

    test "filters posts by type", %{location: location, radius: radius, posts: [p1, p2, p3, p4, _p5]} do
      fields = [:id, :body, :title, :type]

      assert [m1, m2] = Posts.list_markers({location, radius}, types: [:regular])

      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.117661, long: -0.161299},
        posts_count: 1,
        top_posts: m1_posts
      } = m1

      assert m1_posts |> Enum.count() == 1
      assert m1_posts |> Enum.at(0) |> Map.take(fields) == Map.take(p4, fields)

      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.23399, long: -0.138531},
        posts_count: 1,
        top_posts: m2_posts
      } = m2

      assert m2_posts |> Enum.count() == 1
      assert m2_posts |> Enum.at(0) |> Map.take(fields) == Map.take(p1, fields)

      assert [m3] = Posts.list_markers({location, radius}, types: [:event])

      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.180066, long: -0.1517015},
        posts_count: 2,
        top_posts: m3_posts
      } = m3

      assert m3_posts |> Enum.count() == 2
      assert m3_posts |> Enum.at(0) |> Map.take(fields) == Map.take(p3, fields)
      assert m3_posts |> Enum.at(1) |> Map.take(fields) == Map.take(p2, fields)
    end

    test "counts only unique posts", %{location: location, radius: radius, posts: [_p1, p2, _p3, _p4, _p5]} do
      insert(:event, post: p2) # p2 now has 2 events

      assert [_m1, m2, _m3] = Posts.list_markers({location, radius})
      assert m2[:posts_count] == 2
    end

    test "returns location accounting for fake location", %{location: location, radius: radius, posts: [_p1, p2, _p3, _p4, _p5]} do
      from(p in Post, where: p.id == ^p2.id)
      |> Repo.update_all([set: [fake_location: %BillBored.Geo.Point{lat: 51.777, long: -0.134}]])

      assert [_m1, m2, _m3] = Posts.list_markers({location, radius})
      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.4825295, long: -0.136683},
        posts_count: 2
      } = m2
    end

    test "does not return private posts", %{location: location, radius: radius, posts: [_p1, _p2, _p3, p4, p5]} do
      from(p in Post, where: p.id == ^p5.id)
      |> Repo.update_all([set: [private?: true]])

      assert [m1, _m2, _m3] = Posts.list_markers({location, radius})
      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.117661, long: -0.161299},
        posts_count: 1,
        top_posts: [m1_post]
      } = m1

      fields = [:id, :body, :title, :type]
      assert m1_post |> Map.take(fields) == Map.take(p4, fields)
    end

    test "returns empty list when no posts are in the area" do
      assert [] == Posts.list_markers({%BillBored.Geo.Point{lat: 0, long: 0}, 1_000})
    end

    test "filters business posts", %{location: location, radius: radius} do
      business = insert(:business_account)
      post = insert(:post, business_id: business.id, business_name: business.first_name, location: location)

      assert [m1] = Posts.list_markers({location, radius}, is_business: true)
      assert %{
        precision: 5,
        location: %BillBored.Geo.Point{lat: 51.13606981407861, long: -0.17065179253916085},
        posts_count: 1,
        top_posts: [m1_post]
      } = m1

      fields = [:id, :body, :title, :type]
      assert m1_post |> Map.take(fields) == Map.take(post, fields)
    end
  end

  defp create_posts(_context) do
    %Post{} = post1 = insert(:post, location: %BillBored.Geo.Point{lat: 40.5, long: -50.0})
    Enum.each(1..5, fn _ -> insert(:post_upvote, post: post1) end)
    Enum.each(1..4, fn _ -> insert(:post_downvote, post: post1) end)
    Enum.each(1..3, fn _ -> insert(:post_comment, post: post1) end)

    %Post{} = post2 = insert(:post, location: %BillBored.Geo.Point{lat: 40.51, long: -50.0})

    Enum.each(1..3, fn _ -> insert(:post_upvote, post: post2) end)
    Enum.each(1..2, fn _ -> insert(:post_downvote, post: post2) end)

    # shouldn't be found (too far)
    %Post{} = post3 = insert(:post, location: %BillBored.Geo.Point{lat: 0, long: 0})

    # shouldn't be found (not within 24h time frame)
    %Post{} =
      post4 =
      insert(
        :post,
        location: %BillBored.Geo.Point{lat: 40.51, long: -50.0},
        inserted_at: into_past(DateTime.utc_now(), 30)
      )

    {:ok, posts: [post1, post2, post3, post4]}
  end

  @spec add_hours(DateTime.t(), pos_integer) :: DateTime.t()
  defp add_hours(dt, hours) do
    DateTime.add(dt, hours * 60 * 60)
  end

  defp into_past(dt, hours) do
    add_hours(dt, -hours)
  end
end
