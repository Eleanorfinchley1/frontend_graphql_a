defmodule Web.FollowingControllerTest do
  use Web.ConnCase, async: true

  import BillBored.Factory

  describe "index actions" do
    test "for followings", %{conn: conn} = context do
      {:ok, %{tokens: tokens}} = create_users(context)
      users = for t <- tokens, do: t.user

      for i <- 1..75 do
        insert(:user_following, from: hd(users), to: Enum.at(users, i))
      end

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.following_path(conn, :index))
        |> doc()
        |> json_response(200)

      refute resp["prev"]
      assert length(resp["entries"]) == 10
      assert resp["next"] && String.contains?(resp["next"], "page=2")
      assert resp["page_number"] == 1
      assert resp["total_entries"] == 75
      assert resp["total_pages"] == 8

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.following_path(conn, :index, page: 2))
        |> json_response(200)

      assert length(resp["entries"]) == 10
      assert resp["prev"] && String.contains?(resp["prev"], "page=1")
      assert resp["next"] && String.contains?(resp["next"], "page=3")
      assert resp["page_number"] == 2
      assert resp["total_entries"] == 75
      assert resp["total_pages"] == 8

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.following_path(conn, :index, page: 8))
        |> json_response(200)

      assert length(resp["entries"]) == 5
      assert resp["prev"] && String.contains?(resp["prev"], "page=7")
      refute resp["next"]
      assert resp["page_number"] == 8
    end

    test "for followers", %{conn: conn} = context do
      {:ok, %{tokens: tokens}} = create_users(context)
      users = for t <- tokens, do: t.user

      for i <- 1..75 do
        insert(:user_following, from: Enum.at(users, i), to: hd(users))
      end

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.following_path(conn, :index_followers))
        |> doc()
        |> json_response(200)

      refute resp["prev"]
      assert length(resp["entries"]) == 10
      assert resp["next"] && String.contains?(resp["next"], "page=2")
      assert resp["page_number"] == 1
      assert resp["total_entries"] == 75
      assert resp["total_pages"] == 8

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.following_path(conn, :index_followers, page: 2))
        |> json_response(200)

      assert length(resp["entries"]) == 10
      assert resp["prev"] && String.contains?(resp["prev"], "page=1")
      assert resp["next"] && String.contains?(resp["next"], "page=3")
      assert resp["page_number"] == 2
      assert resp["total_entries"] == 75
      assert resp["total_pages"] == 8

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.following_path(conn, :index_followers, page: 8))
        |> json_response(200)

      assert length(resp["entries"]) == 5
      assert resp["prev"] && String.contains?(resp["prev"], "page=7")
      refute resp["next"]
      assert resp["page_number"] == 8
    end
  end

  describe "user followers" do
    setup do
      [u1, u2, u3] = insert_list(3, :user)

      insert(:user_following, from: u2, to: u1)
      insert(:user_following, from: u3, to: u1)
      insert(:user_following, from: u1, to: u3)

      %{users: [u1, u2, u3]}
    end

    test "returns error on invalid user id", %{conn: conn, users: [_u1, u2, _u3]} do
      resp =
        conn
        |> authenticate(u2)
        |> get(Routes.following_path(conn, :user_followers, "bad"))
        |> json_response(422)

      assert %{
        "error" => "invalid_param_type",
        "reason" => "invalid_param_type",
        "success" => false
      } == resp
    end

    test "returns user followers", %{conn: conn, users: [u1, u2, u3]} do
      resp =
        conn
        |> authenticate(u2)
        |> get(Routes.following_path(conn, :user_followers, u1.id))
        |> doc()
        |> json_response(200)

      assert %{
        "entries" => [%{"id" => id1}, %{"id" => id2}],
        "next" => nil,
        "page_number" => 1,
        "page_size" => 10,
        "prev" => nil,
        "total_entries" => 2,
        "total_pages" => 1
      } = resp

      assert Enum.sort([id1, id2]) == Enum.sort([u2.id, u3.id])
    end

    test "returns other user followers", %{conn: conn, users: [%{id: u1_id}, u2, u3]} do
      resp =
        conn
        |> authenticate(u2)
        |> get(Routes.following_path(conn, :user_followers, u3.id))
        |> json_response(200)

      assert %{
        "entries" => [%{"id" => ^u1_id}],
        "next" => nil,
        "page_number" => 1,
        "page_size" => 10,
        "prev" => nil,
        "total_entries" => 1,
        "total_pages" => 1
      } = resp
    end

    test "returns user followers page", %{conn: conn, users: [u1, u2, _u3]} do
      resp =
        conn
        |> authenticate(u2)
        |> get(Routes.following_path(conn, :user_followers, u1.id, page_size: 1, page: 2))
        |> json_response(200)

      assert %{
        "entries" => [%{"id" => _id}],
        "next" => nil,
        "page_number" => 2,
        "page_size" => 1,
        "prev" => _,
        "total_entries" => 2,
        "total_pages" => 2
      } = resp
    end
  end

  describe "follow suggestions" do
    setup %{conn: conn} do
      %{user: user, key: token} =
        insert(:auth_token,
          user:
            build(:user,
              prefered_radius: 10,
              user_real_location: %BillBored.Geo.Point{lat: 37.773972, long: -122.431297}
            )
        )

      {:ok, conn: authenticate(conn, token), user: user}
    end

    test "when there are more than 10 interest/location suggestions", %{conn: conn, user: user} do
      [u1 | _rest] =
        _nearby_users =
        insert_list(8, :user,
          user_real_location: %BillBored.Geo.Point{lat: 37.773972, long: -122.431297}
        )

      music_interest = insert(:interest, hashtag: "music")
      events_interest = insert(:interest, hashtag: "events")
      insert(:user_interest, user: user, interest: music_interest)
      insert(:user_interest, user: user, interest: events_interest)

      maps_interest = insert(:interest, hashtag: "maps")

      [%{user: u9}, %{user: u10}, %{user: u11}] =
        insert_list(3, :user_interest, interest: maps_interest)

      insert(:user_interest, user: u9, interest: music_interest)
      insert(:user_interest, user: u11, interest: events_interest)
      insert(:user_interest, user: u10, interest: events_interest)
      insert(:user_interest, user: u10, interest: music_interest)
      insert(:user_interest, user: u1, interest: music_interest)
      insert(:user_interest, user: u1, interest: events_interest)

      assert %{"page_number" => 1, "page_size" => 10, "total_entries" => 11, "total_pages" => 2} =
               conn
               |> get(Routes.following_path(conn, :follow_suggestions))
               |> json_response(200)
    end

    test "when there are less than 10 interest/location suggestions we add oldest/most popular users",
         %{conn: conn} do
      insert_list(30, :user)
      most_followed = insert_list(20, :user)

      most_followed
      |> Enum.with_index()
      |> Enum.each(fn {followed, index} ->
        insert_list(index, :user_following, to: followed)
      end)

      insert_list(3, :user,
        user_real_location: %BillBored.Geo.Point{lat: 37.773972, long: -122.431297}
      )

      assert %{
               "page_number" => 1,
               "page_size" => page_size,
               "total_entries" => page_size,
               "next" => nil,
               "prev" => nil,
               "total_pages" => 1,
               "entries" => users
             } =
               conn
               |> get(Routes.following_path(conn, :follow_suggestions))
               |> json_response(200)

      assert page_size == length(users)
      # ensure suggested, oldest, and most popular users are not duplicated
      assert length(Enum.uniq_by(users, & &1["id"])) == length(users)
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..100, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
