defmodule Web.FollowingController do
  use Web, :controller
  alias BillBored.{Users, User}

  action_fallback(Web.FallbackController)

  def action(
        %Plug.Conn{
          params: params,
          assigns: %{
            user_id: user_id
          }
        } = conn,
        _opts
      ) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def index(conn, params, user_id) do
    users = User.Followings.index(user_id, params)
    render(conn, "index.json", data: users)
  end

  @user_followings_params [
    {"id", :id, false, :integer},
    {"page", :page, false, :integer},
    {"page_size", :page_size, false, :integer}
  ]

  def user_followings(conn, params, _user_id) do
    with {:ok, %{id: user_id} = valid_params} <- validate_params(@user_followings_params, params) do
      users = User.Followings.index(user_id, valid_params)
      render(conn, "index.json", data: users)
    end
  end

  def index_followers(conn, params, user_id) do
    render(conn, "followers.json",
      followers: User.Followings.index_followers(user_id, params),
      friend_ids: Users.list_friend_ids(user_id)
    )
  end

  @user_followers_params [
    {"id", :id, false, :integer},
    {"page", :page, false, :integer},
    {"page_size", :page_size, false, :integer}
  ]

  def user_followers(conn, params, _user_id) do
    with {:ok, %{id: user_id} = valid_params} <- validate_params(@user_followers_params, params) do
      # render(conn, "user_followers.json", followers: User.Followings.index_followers(user_id, valid_params))
      render(conn, "followers.json",
        followers: User.Followings.index_followers(user_id, valid_params),
        friend_ids: Users.list_friend_ids(user_id)
      )
    end
  end

  def follow_suggestions(conn, params, user_id) do
    user = Users.get!(user_id)
    followed_users = Users.followed_users(user)

    # TODO simplify
    user
    |> Users.follow_suggestions_query(followed_users)
    |> Repo.paginate(params)
    |> case do
      %Scrivener.Page{entries: suggestions, page_number: 1, page_size: 10} = data ->
        if length(suggestions) < 10 do
          oldest_users = Users.oldest_users(user, followed_users)
          most_followed_users = Users.most_followed_users(user, followed_users)

          # there might be the same users returned by the above queries so we uniq them
          all_suggestions =
            Enum.uniq_by(suggestions ++ most_followed_users ++ oldest_users, & &1.id)

          count = length(all_suggestions)

          # TODO simplify
          render(conn, "index.json",
            data: %Scrivener.Page{
              entries: all_suggestions,
              page_number: 1,
              page_size: count,
              total_pages: 1,
              total_entries: count
            }
          )
        else
          render(conn, "index.json", data: data)
        end

      data ->
        render(conn, "index.json", data: data)
    end
  end

  def create(conn, %{"add" => add, "remove" => remove}, user_id) do
    remove = (is_list(remove) && remove) || [remove]
    add = (is_list(add) && add) || [add]

    remove
    |> Users.get_users_id_by_username()
    |> User.Followings.delete_all(user_id)

    # TODO why do we delete the followings here?
    add
    |> Users.get_users_id_by_username()
    |> User.Followings.delete_all(user_id)

    # TODO can be done in a single query instead of n
    add
    |> Users.get_users_id_by_username()
    |> Enum.map(&User.Followings.create(%{to_userprofile_id: &1, from_userprofile_id: user_id}))

    conn
    |> put_status(201)
    # TODO the result message is useless
    |> json(%{success: true, result: "Followers list is updated!"})
  end

  def create(conn, %{"add" => _add} = params, user_id) do
    create(conn, Map.put(params, "remove", []), user_id)
  end

  def create(conn, %{"remove" => _remove} = params, user_id) do
    create(conn, Map.put(params, "add", []), user_id)
  end
end
