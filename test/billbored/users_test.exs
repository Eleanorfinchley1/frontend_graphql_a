defmodule BillBored.UsersTest do
  use BillBored.DataCase, async: true
  alias BillBored.{Users, User}

  describe "follow_suggestions_query/1" do
    setup do
      {:ok,
       user:
         insert(:user,
           prefered_radius: 10,
           user_real_location: %BillBored.Geo.Point{lat: 37.773972, long: -122.431297}
         )}
    end

    test "when the user has no interests and there are no users nearby", %{user: user} do
      assert [] == user |> Users.follow_suggestions_query([]) |> Repo.all()
    end

    test "when there are no other users at all", %{user: user} do
      insert(:user_interest, user: user, interest: build(:interest, hashtag: "music"))
      insert(:user_interest, user: user, interest: build(:interest, hashtag: "events"))

      assert [] == user |> Users.follow_suggestions_query([]) |> Repo.all()
    end

    test "when there are users with no common interests and no users nearby", %{user: user} do
      insert(:user_interest, user: user, interest: build(:interest, hashtag: "music"))
      insert(:user_interest, user: user, interest: build(:interest, hashtag: "events"))

      maps_interest = insert(:interest, hashtag: "maps")
      running_interest = insert(:interest, hashtag: "running")
      insert_list(3, :user_interest, interest: maps_interest)
      insert(:user_interest, interest: maps_interest)
      insert(:user_interest, interest: running_interest)

      assert [] == user |> Users.follow_suggestions_query([]) |> Repo.all()
    end

    test "when there are users with common interests but no users nearby", %{user: user} do
      music_interest = insert(:interest, hashtag: "music")
      events_interest = insert(:interest, hashtag: "events")
      insert(:user_interest, user: user, interest: music_interest)
      insert(:user_interest, user: user, interest: events_interest)

      maps_interest = insert(:interest, hashtag: "maps")
      running_interest = insert(:interest, hashtag: "running")

      [%{user: %{id: u1_id} = u1}, %{user: %{id: u2_id} = u2}, _ui3] =
        insert_list(3, :user_interest, interest: maps_interest)

      insert(:user_interest, user: u1, interest: running_interest)
      insert(:user_interest, user: u1, interest: music_interest)
      insert(:user_interest, user: u2, interest: running_interest)
      insert(:user_interest, user: u2, interest: events_interest)
      insert(:user_interest, user: u2, interest: music_interest)

      suggested_users = Users.follow_suggestions_query(user, []) |> Repo.all()
      assert [u1_id, u2_id] == sorted_ids(suggested_users)
    end

    test "when there are no users nearby", %{user: user} do
      insert_list(3, :user,
        user_real_location: %BillBored.Geo.Point{lat: 41.881832, long: -87.623177}
      )

      assert [] == user |> Users.follow_suggestions_query([]) |> Repo.all()
    end

    test "when there are users nearby", %{user: user} do
      insert_list(3, :user,
        user_real_location: %BillBored.Geo.Point{lat: 41.881832, long: -87.623177}
      )

      [%{id: u1_id}, %{id: u2_id}, %{id: u3_id}] =
        insert_list(3, :user,
          user_real_location: %BillBored.Geo.Point{lat: 37.773972, long: -122.431297}
        )

      suggested_users = Users.follow_suggestions_query(user, []) |> Repo.all()
      assert [u1_id, u2_id, u3_id] == sorted_ids(suggested_users)
    end

    test "when users with common interest intersect with users nearby", %{user: user} do
      [%{id: u1_id}, %{id: u2_id} = u2, %{id: u3_id}] =
        insert_list(3, :user,
          user_real_location: %BillBored.Geo.Point{lat: 37.773972, long: -122.431297}
        )

      music_interest = insert(:interest, hashtag: "music")
      events_interest = insert(:interest, hashtag: "events")
      insert(:user_interest, user: user, interest: music_interest)
      insert(:user_interest, user: user, interest: events_interest)

      maps_interest = insert(:interest, hashtag: "maps")
      running_interest = insert(:interest, hashtag: "running")

      [%{user: %{id: u4_id} = u4}, %{user: %{id: u5_id} = u5}, _ui3] =
        insert_list(3, :user_interest, interest: maps_interest)

      insert(:user_interest, user: u4, interest: running_interest)
      insert(:user_interest, user: u4, interest: music_interest)
      insert(:user_interest, user: u5, interest: running_interest)
      insert(:user_interest, user: u5, interest: events_interest)
      insert(:user_interest, user: u5, interest: music_interest)
      insert(:user_interest, user: u2, interest: music_interest)
      insert(:user_interest, user: u2, interest: events_interest)

      suggested_users = Users.follow_suggestions_query(user, []) |> Repo.all()
      assert [u1_id, u2_id, u3_id, u4_id, u5_id] == sorted_ids(suggested_users)
    end
  end

  describe "oldest_users/1" do
    test "it works" do
      [%{id: u1_id} = u1, %{id: u2_id} = u2, %{id: u3_id} = u3] = insert_list(3, :user)
      assert [%User{id: ^u2_id}, %User{id: ^u3_id}] = sorted_by_id(Users.oldest_users(u1, []))
      assert [%User{id: ^u1_id}, %User{id: ^u3_id}] = sorted_by_id(Users.oldest_users(u2, []))
      assert [%User{id: ^u1_id}, %User{id: ^u2_id}] = sorted_by_id(Users.oldest_users(u3, []))
    end

    test "does not return blocked users" do
      [%{id: u1_id} = u1, %{id: u2_id} = u2, %{id: u3_id} = u3] = insert_list(3, :user)
      insert(:user_block, blocker: u1, blocked: u2)

      assert [%User{id: ^u3_id}] = sorted_by_id(Users.oldest_users(u1, []))
      assert [%User{id: ^u3_id}] = sorted_by_id(Users.oldest_users(u2, []))
      assert [%User{id: ^u1_id}, %User{id: ^u2_id}] = sorted_by_id(Users.oldest_users(u3, []))
    end

    test "does not return banned users" do
      [%{id: u1_id} = u1, %{id: u2_id} = u2] = insert_list(2, :user)
      insert(:user, banned?: true)

      assert [%User{id: ^u2_id}] = sorted_by_id(Users.oldest_users(u1, []))
      assert [%User{id: ^u1_id}] = sorted_by_id(Users.oldest_users(u2, []))
    end
  end

  describe "most_followed_users/1" do
    test "it works" do
      [u1, %{id: u2_id} = u2, %{id: u3_id} = u3] = insert_list(3, :user)

      insert(:user_following, from: u1, to: u2)
      insert(:user_following, from: u1, to: u3)
      insert(:user_following, from: u2, to: u3)

      assert [%User{id: ^u2_id}, %User{id: ^u3_id}] =
               sorted_by_id(Users.most_followed_users(u1, []))

      # u1 is not returned because he isn't followed by anyone
      assert [%User{id: ^u3_id}] = sorted_by_id(Users.most_followed_users(u2, []))
      assert [%User{id: ^u2_id}] = sorted_by_id(Users.most_followed_users(u3, []))
    end

    test "does not return blocked users" do
      [%{id: u1_id} = u1, %{id: u2_id} = u2, %{id: u3_id} = u3] = insert_list(3, :user)

      insert(:user_following, to: u1)
      insert(:user_following, to: u2)
      insert(:user_following, to: u3)
      insert(:user_block, blocker: u1, blocked: u2)

      assert [%User{id: ^u3_id}] = sorted_by_id(Users.most_followed_users(u1, []))
      assert [%User{id: ^u3_id}] = sorted_by_id(Users.most_followed_users(u2, []))

      assert [%User{id: ^u1_id}, %User{id: ^u2_id}] =
               sorted_by_id(Users.most_followed_users(u3, []))
    end

    test "does not return banned users" do
      [%{id: u1_id} = u1, %{id: u2_id} = u2] = insert_list(2, :user)
      u3 = insert(:user, banned?: true)

      insert(:user_following, to: u1)
      insert(:user_following, to: u2)
      insert(:user_following, to: u3)

      assert [%User{id: ^u2_id}] = sorted_by_id(Users.most_followed_users(u1, []))
      assert [%User{id: ^u1_id}] = sorted_by_id(Users.most_followed_users(u2, []))
    end
  end

  describe "list_followers/1" do
    setup do
      {:ok, user: insert(:user)}
    end

    test "when has no followers", %{user: user} do
      assert [] == Users.list_followers(user.id)
    end

    test "when has followers", %{user: user} do
      followers = insert_list(3, :user_following, to: user)
      _followings = insert_list(3, :user_following, from: user)

      [f1, f2, f3] = Enum.map(followers, & &1.from.id)

      assert [%User{id: ^f1}, %User{id: ^f2}, %User{id: ^f3}] = Users.list_followers(user.id)
    end

    test "does not return banned followers", %{user: user} do
      followings = insert_list(2, :user_following, to: user)
      insert(:user_following, to: user, from: insert(:user, banned?: true))

      [f1, f2] = Enum.map(followings, & &1.from.id)
      assert [%User{id: ^f1}, %User{id: ^f2}] = Users.list_followers(user.id)
    end
  end

  describe "update_online_statuses" do
    setup do
      u1 = insert(:user, last_online_at: ~U[2000-01-01 00:00:00Z])
      u2 = insert(:user)

      %{users: [u1, u2]}
    end

    test "updates last_online_at", %{users: [u1, u2]} do
      Users.update_online_statuses(%{
        u1.id => ~U[2021-10-10 10:20:30Z],
        u2.id => ~U[2021-10-10 10:20:35.123456Z]
      })

      assert %{last_online_at: ~U[2021-10-10 10:20:30.000000Z]} = Repo.get(User, u1.id)
      assert %{last_online_at: ~U[2021-10-10 10:20:35.123456Z]} = Repo.get(User, u2.id)
    end
  end

  describe "get_user_profile" do
    setup do
      [u1, u2, u3] = insert_list(3, :user)
      insert(:user_following, to: u1, from: u2)
      insert(:user_following, from: u1, to: u3)
      insert(:user_following, from: u1, to: u2)

      %{users: [u1, u2, u3]}
    end

    test "returns followings status", %{users: [u1, u2, u3]} do
      %{username: username, id: id} = u3

      assert %User{
               id: ^id,
               username: ^username,
               is_following: true,
               is_follower: false
             } = Users.get_user_profile(u3.username, %{for_id: u1.id})

      %{username: username, id: id} = u2

      assert %User{
               id: ^id,
               username: ^username,
               is_following: true,
               is_follower: true
             } = Users.get_user_profile(u2.username, %{for_id: u1.id})

      assert %User{
               id: ^id,
               username: ^username,
               is_following: false,
               is_follower: false
             } = Users.get_user_profile(u2.username, %{for_id: u3.id})

      %{username: username, id: id} = u1

      assert %User{
               id: ^id,
               username: ^username,
               is_following: false,
               is_follower: true
             } = Users.get_user_profile(u1.username, %{for_id: u3.id})
    end
  end
end
