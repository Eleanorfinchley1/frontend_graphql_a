defmodule Web.FollowingView do
  use Web, :view

  def render("index.json", %{conn: conn, data: entries}) do
    Web.ViewHelpers.index(conn, entries, Web.UserView)
  end

  def render("followers.json", %{
        conn: conn,
        followers: %{entries: followers} = paginated_followers,
        friend_ids: friend_ids
      }) do
    friend_ids = MapSet.new(friend_ids)

    followers =
      Enum.map(followers, fn user ->
        Map.put(user, :followed?, MapSet.member?(friend_ids, user.id))
      end)

    Web.ViewHelpers.index(
      conn,
      %{paginated_followers | entries: followers},
      __MODULE__
    )
  end

  def render("user_followers.json", %{conn: conn, followers: followers}) do
    Web.ViewHelpers.index(conn, followers, Web.UserView)
  end

  def render("show.json", %{following: follower}) do
    "show.json"
    |> Web.UserView.render(%{user: follower})
    |> Map.put("is_followed", follower.followed?)
  end
end
