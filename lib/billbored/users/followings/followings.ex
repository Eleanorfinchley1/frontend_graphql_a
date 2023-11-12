defmodule BillBored.User.Followings do
  import Ecto.Query
  alias BillBored.User
  alias BillBored.User.Followings.Following
  alias Ecto.Multi

  def index(user_id, params) do
    Following
    |> join(:inner, [f], u in assoc(f, :to))
    |> where([f, u], f.from_userprofile_id == ^user_id)
    |> select([_f, u], u)
    |> Repo.paginate(params)
  end

  def index_followers(user_id, params) do
    Following
    |> join(:inner, [f], u in assoc(f, :from))
    |> where([f, u], f.to_userprofile_id == ^user_id)
    |> select([_f, u], u)
    |> Repo.paginate(params)
  end

  def create(attrs \\ %{}) do
    Multi.new()
    |> Multi.insert(:following, Following.changeset(%Following{}, attrs))
    |> Multi.run(:notifications, fn _repo, %{following: following} ->
      following = Repo.preload(following, [:from, [to: :devices]])
      Notifications.process_new_following(following)
      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{following: following}} -> {:ok, following}
      {:error, :following, changeset, _changes} -> {:error, changeset}
    end
  end

  def update(%Following{} = following, attrs \\ %{}) do
    following
    |> Following.changeset(attrs)
    |> Repo.update()
  end

  def delete_all(follow_ids, user_id) do
    Following
    |> where([f], f.from_userprofile_id == ^user_id)
    |> where([f], f.to_userprofile_id in ^follow_ids)
    |> Repo.delete_all()
  end

  def delete_between(%User{id: user1_id}, %User{id: user2_id}), do: delete_between(user1_id, user2_id)
  def delete_between(user1_id, user2_id) do
    Following
    |> where([f], f.from_userprofile_id == ^user1_id and f.to_userprofile_id == ^user2_id)
    |> or_where([f], f.to_userprofile_id == ^user1_id and f.from_userprofile_id == ^user2_id)
    |> Repo.delete_all()
  end
end
