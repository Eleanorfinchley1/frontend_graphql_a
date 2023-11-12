defmodule Web.CloseFriendsView do
  use Web, :view

  def render("close_friends.json", %{
        count: close_friends_count,
        close_friends: close_friends,
        requests: %{
          count: close_friend_requests_count,
          close_friends: close_friend_requests
        }
      }) do
    %{
      count: close_friends_count,
      close_friends: render_many(close_friends, Web.UserView, "user.json"),
      requests: %{
        count: close_friend_requests_count,
        close_friends: render_many(close_friend_requests, Web.UserView, "user.json")
      }
    }
  end
end
