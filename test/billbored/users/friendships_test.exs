defmodule BillBored.UserFriendshipsTest do
  use BillBored.DataCase, async: true

  alias BillBored.{User, Users}

  setup do
    user = insert(:user)

    # creates some followers who we don't follow (not friends)
    just_followers =
      Enum.map(1..3, fn _ ->
        %User.Followings.Following{from: follower} = insert(:user_following, to: user)
        follower
      end)

    # creates some people we follow, but they don't follow back (not friends)
    just_followees =
      Enum.map(1..3, fn _ ->
        %User.Followings.Following{to: followee} = insert(:user_following, from: user)
        followee
      end)

    # creates some users who will become "friends"
    friends =
      Enum.map(1..3, fn _ ->
        insert(:user)
      end)

    # we follow them, they follow us (this makes them friends)
    Enum.map(friends, fn friend ->
      insert_user_friendship(users: [user, friend])
    end)

    %{
      user: user,
      just_followers: just_followers,
      just_followees: just_followees,
      friends: friends
    }
  end

  test "list_friend_ids/1", %{user: %User{id: user_id}, friends: friends} do
    fetched_friend_ids = Users.list_friend_ids(user_id)

    # TODO sort if the lists have the same elements but in different order
    assert fetched_friend_ids == Enum.map(friends, fn %User{id: friend_id} -> friend_id end)
  end
end
