defmodule Web.FriendChannelTest do
  use Web.ChannelCase
  alias BillBored.User

  setup do
    %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)

    # creates some users who will become "friends"
    friends =
      Enum.map(1..3, fn _ ->
        insert(:user)
      end)

    # we follow them, they follow us (this makes them friends)
    Enum.map(friends, fn friend ->
      insert_user_friendship(users: [user, friend])
    end)

    {:ok, %Phoenix.Socket{} = our_socket} = connect(Web.UserSocket, %{"token" => token})

    # connects each friend
    friend_sockets =
      Enum.map(friends, fn %User{id: friend_id} = friend ->
        socket = socket(Web.UserSocket, "user_socket:#{friend_id}", %{user: friend})
        subscribe_and_join!(socket, "friends", %{})
      end)

    %{
      user: user,
      our_socket: our_socket,
      friends: friends,
      friend_sockets: friend_sockets
    }
  end

  test "go online and then offline", %{
    user: %User{id: user_id},
    our_socket: our_socket,
    friend_sockets: friend_sockets
  } do
    # we are now "online"
    our_socket = subscribe_and_join!(our_socket, "friends", %{})

    # so that our friends now should receive a message about it
    Enum.each(friend_sockets, fn _friend_socket ->
      assert_push("friend:online", %{"user_id" => ^user_id})
    end)

    # now we leave
    Process.flag(:trap_exit, true)
    _ref = leave(our_socket)

    assert_receive {:socket_close, _pid, {:shutdown, :left}}
    assert_receive {:EXIT, _pid, {:shutdown, :left}}

    # and our friends receive a message about it again
    Enum.each(friend_sockets, fn _friend_socket ->
      assert_push("friend:offline", %{"user_id" => ^user_id})
    end)
  end
end
