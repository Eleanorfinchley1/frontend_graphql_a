defmodule Web.CloseFriendsController do
  use Web, :controller
  alias BillBored.{Users, User}

  # action_fallback(Web.FallbackController)

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def close_friends(conn, params, user_id) do
    add = Map.get(params, "add", [])
    remove = Map.get(params, "remove", [])

    if is_list(add) && is_list(remove) do
      Enum.each(add, fn username ->
        user_to = Users.get_by(username: username)
        Users.create_close_friendship(user_id, user_to.id)
      end)

      Enum.each(remove, fn username ->
        user_to = Users.get_by(username: username)

        close_friendship =
          Repo.get_by(
            User.CloseFriendship,
            from_userprofile_id: user_id,
            to_userprofile_id: user_to.id
          )

        if close_friendship do
          Users.delete_close_friendship(close_friendship)
        end
      end)

      close_friends = Users.get_close_friends(user_id)
      close_friend_requests = Users.get_close_friend_requests(user_id)

      render(conn, "close_friends.json", %{
        count: Enum.count(close_friends),
        close_friends: close_friends,
        requests: %{
          count: Enum.count(close_friend_requests),
          close_friends: close_friend_requests
        }
      })
    else
      message = %{details: "\"add\" and/or \"remove\" should be lists with usernames."}
      send_resp(conn, 404, Jason.encode!(message, pretty: true))
    end
  end
end
