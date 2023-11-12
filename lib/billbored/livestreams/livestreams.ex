defmodule BillBored.Livestreams do
  @moduledoc ""
  import Ecto.Query

  alias BillBored.{Livestream, Users}
  alias Livestream.{Comment, Vote, View}

  @spec create(BillBored.attrs(), owner_id: pos_integer) ::
          {:ok, Livestream.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs, owner_id: owner_id) do
    %Livestream{owner_id: owner_id}
    |> Livestream.changeset(attrs)
    |> Repo.insert()
  end

  def delayed_publish(<<livestream_id::36-bytes>>, user_id) do
    # TODO replace with a job queue?
    # Delay livestream publishing for 50s
    Task.start(fn ->
      :timer.sleep(:timer.seconds(50))

      # sets livestream.active? to true and pushes "livestream:new" to socket
      case BillBored.Livestreams.get(livestream_id) do
        %BillBored.Livestream{owner_id: ^user_id} = livestream ->
          BillBored.Livestreams.InMemory.publish(livestream_id)
          followers = user_id |> Users.list_followers() |> Repo.preload(:devices)

          Notifications.process_published_livestream(
            livestream: Repo.preload(livestream, :owner),
            receivers: followers
          )

          :ok

        _ ->
          :ok
      end
    end)
  end

  @spec mark_recorded(Ecto.UUID.t(), pos_integer) :: Livestream.t()
  def mark_recorded(<<livestream_id::36-bytes>>, user_id) do
    {1, [%Livestream{} = livestream]} =
      Livestream
      |> where(id: ^livestream_id)
      |> where(owner_id: ^user_id)
      |> select([l], l)
      |> Repo.update_all(set: [recorded?: true])

    livestream
  end

  def get_livestreams_by_userid(user_id) do
    Livestream
    |> where(owner_id: ^user_id)
    |> where(recorded?: true)
    |> order_by(desc: :created)
    |> Repo.all()
  end

  def delete(livestream) do
    Repo.delete(livestream)
  end

  @spec create_comment(BillBored.attrs(), livestream_id: Ecto.UUID.t(), author_id: pos_integer) ::
          {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def create_comment(attrs, livestream_id: livestream_id, author_id: author_id) do
    %Comment{livestream_id: livestream_id, author_id: author_id}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  def comments_list_with_votes(<<l_id::36-bytes>>, current_u_id) do
    upvote = "upvote"
    downvote = "downvote"

    Comment
    |> where(livestream_id: ^l_id)
    |> join(:left, [c], a in assoc(c, :author))
    |> join(:left, [c, a], v in assoc(c, :votes))
    |> group_by([c, a, v], c.id)
    |> group_by([c, a, v], a.username)
    |> select([c, a, v], %{
      id: c.id,
      body: c.body,
      author: a.username,
      upvote: count(fragment("case ? when ? then 1 else null end", v.vote_type, ^upvote)),
      current_user_upvote:
        count(
          fragment(
            "case (? = ? and ? = ?) when true then 1 else null end",
            v.vote_type,
            ^upvote,
            v.user_id,
            ^current_u_id
          )
        ),
      current_user_downvote:
        count(
          fragment(
            "case (? = ? and ? = ?) when true then 1 else null end",
            v.vote_type,
            ^downvote,
            v.user_id,
            ^current_u_id
          )
        ),
      downvote: count(fragment("case ? when ? then 1 else null end", v.vote_type, ^downvote))
    })
    |> Repo.all()
  end

  def check_and_create_view(u_id, l_id) when nil in [u_id, l_id],
    do: {:error, "id can not be nil"}

  def check_and_create_view(u_id, <<l_id::36-bytes>>) do
    case View |> where([v], v.user_id == ^u_id and v.livestream_id == ^l_id) |> Repo.one() do
      nil ->
        %View{livestream_id: l_id, user_id: u_id}
        |> View.changeset()
        |> Repo.insert()

      _view ->
        :ok
    end
  end

  def create_or_update_vote(u_id, l_id, _v_type) when nil in [u_id, l_id],
    do: {:error, "id can not be nil"}

  # TODO use insert_all with conflict: :update
  def create_or_update_vote(u_id, <<l_id::36-bytes>>, v_type)
      when v_type in ["upvote", "downvote"] do
    Vote
    |> where([v], v.user_id == ^u_id and v.livestream_id == ^l_id)
    |> Repo.all()
    |> case do
      [] ->
        %Vote{vote_type: v_type, livestream_id: l_id, user_id: u_id}
        |> Vote.changeset()
        |> Repo.insert()

      [vote] ->
        vote
        |> Vote.changeset(%{vote_type: v_type})
        |> Repo.update()
    end
    |> case do
      {:ok, _vote} -> :ok
      other -> other
    end
  end

  def create_or_update_vote(u_id, <<l_id::36-bytes>>, _v_type) do
    Vote |> where([v], v.user_id == ^u_id and v.livestream_id == ^l_id) |> Repo.delete_all()
    :ok
  end

  def create_or_update_comment_vote(u_id, c_id, _v_type) when nil in [u_id, c_id],
    do: {:error, "id can not be nil"}

  # TODO use insert_all with conflict: :update
  def create_or_update_comment_vote(u_id, c_id, v_type) when v_type in ["upvote", "downvote"] do
    Comment.Vote
    |> where([v], v.user_id == ^u_id and v.comment_id == ^c_id)
    |> Repo.all()
    |> case do
      [] ->
        %Comment.Vote{user_id: u_id, comment_id: c_id, vote_type: v_type}
        |> Comment.Vote.changeset()
        |> Repo.insert()

      [vote] ->
        vote
        |> Comment.Vote.changeset(%{vote_type: v_type})
        |> Repo.update()
    end
    |> case do
      {:ok, _vote} -> :ok
      other -> other
    end
  end

  def create_or_update_comment_vote(u_id, c_id, _v_type) do
    Comment.Vote
    |> where([v], v.user_id == ^u_id and v.comment_id == ^c_id)
    |> Repo.delete_all()

    :ok
  end

  @spec get(Ecto.UUID.t()) :: Livestream.t() | nil
  def get(<<livestream_id::36-bytes>>) do
    Repo.get(Livestream, livestream_id)
  end

  @spec get_livestream!(Ecto.UUID.t()) :: Livestream.t()
  def get_livestream!(<<livestream_id::36-bytes>>) do
    Repo.get!(Livestream, livestream_id)
  end

  @spec get_comment_by(Keyword.t()) :: Livestream.Comment.t() | nil
  def get_comment_by(constraints) do
    Repo.get_by(Livestream.Comment, constraints)
  end

  @spec list_active :: [Livestream.t()]
  def list_active do
    Livestream
    |> where(active?: true)
    |> Repo.all()
  end

  # TODO refactor
  @spec change_status(Ecto.UUID.t(), boolean) :: Livestream.t()
  def change_status(<<livestream_id::36-bytes>>, active?) do
    {1, [%Livestream{} = livestream]} =
      Livestream
      |> where(id: ^livestream_id)
      |> select([l], l)
      |> Repo.update_all(set: [active?: active?])

    livestream
  end

  defmacrop last_day(created) do
    quote do
      fragment("? > (now() + '-1 day')::timestamp", unquote(created))
    end
  end

  def list_by_location(_, params \\ %{})

  @spec list_by_location(%BillBored.Geo.Point{}, %{radius_in_m: pos_integer()}) :: [
          Livestream.t()
        ]
  def list_by_location(%BillBored.Geo.Point{} = point, %{radius_in_m: radius_in_m} = params) do
    import Geo.PostGIS, only: [st_dwithin_in_meters: 3]

    Livestream.available(params)
    |> where(active?: true)
    |> or_where(recorded?: true)
    |> where([l], last_day(l.created))
    |> where([l], st_dwithin_in_meters(l.location, ^point, ^radius_in_m))
    |> preload([:owner])
    |> Repo.all()
  end

  @spec list_by_location(%BillBored.Geo.Polygon{}, map()) :: [Livestream.t()]
  def list_by_location(%BillBored.Geo.Polygon{} = polygon, params) do
    import Geo.PostGIS, only: [st_covered_by: 2]

    Livestream.available(params)
    |> where(active?: true)
    |> or_where(recorded?: true)
    |> where([l], last_day(l.created))
    |> where([l], st_covered_by(l.location, ^polygon))
    |> Repo.all()
  end
end
