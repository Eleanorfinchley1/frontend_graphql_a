defmodule BillBored.Polls do
  import Ecto.Query

  alias Ecto.Multi
  alias BillBored.{Poll, PollItem}

  def get(id, opts \\ []) do
    poll =
      Poll
      |> where(id: ^id)
      |> preload(items: :media_files)
      |> Repo.one()
      |> add_statistics(opts[:for_id] || (opts[:for] && opts[:for].id) || -1)

    unless opts[:for_id] || opts[:for] do
      items =
        for item <- poll.items do
          Map.put(item, :user_voted?, nil)
        end

      put_in(poll.items, items)
    end || poll
  end

  def get!(id, opts \\ []) do
    poll =
      Poll
      |> where(id: ^id)
      |> preload(items: :media_files)
      |> Repo.one!()
      |> add_statistics(opts[:for_id] || (opts[:for] && opts[:for].id) || -1)

    unless opts[:for_id] || opts[:for] do
      items =
        for item <- poll.items do
          Map.put(item, :user_voted?, nil)
        end

      put_in(poll.items, items)
    end || poll
  end

  # TODO: rewrite¡
  # Maybe, using `Multi`.
  def add_statistics(nil, _user_id), do: nil

  def add_statistics(%{id: poll_id} = poll, user_id) do
    user_voted =
      PollItem.Vote
      |> where(user_id: ^user_id)
      |> join(:left, [piv], pi in assoc(piv, :poll_item))
      |> group_by([piv, pi], pi.id)
      |> where([piv, pi], pi.poll_id == ^poll_id)
      |> select([piv, pi], %{poll_item_id: pi.id, count: count(piv.id)})

    votes_count =
      PollItem.Vote
      |> join(:left, [piv], pi in assoc(piv, :poll_item))
      |> group_by([piv, pi], pi.id)
      |> where([piv, pi], pi.poll_id == ^poll_id)
      |> select([piv, pi], %{poll_item_id: pi.id, count: count(piv.id)})

    items =
      PollItem
      |> where(poll_id: ^poll_id)
      |> preload(:media_files)
      |> join(:left, [pi], vc in subquery(votes_count), on: pi.id == vc.poll_item_id)
      |> join(:left, [pi, vc], uv in subquery(user_voted), on: pi.id == uv.poll_item_id)
      |> select([pi, vc, uv], %{pi | votes_count: vc.count, user_voted?: uv.count > 0})
      |> Repo.all()

    items =
      for item <- items do
        %{
          item
          | votes_count: item.votes_count || 0,
            user_voted?: item.user_voted? || false
        }
      end

    put_in(poll.items, items)
  end

  def delete_poll(poll_id) do
    Poll
    |> where(id: ^poll_id)
    |> Repo.delete_all()
  end

  def delete_poll_item(poll_item_id) do
    PollItem
    |> where(id: ^poll_item_id)
    |> Repo.delete_all()
  end

  def vote!(poll_item, user_id) do
    # TODO why is it necessary?
    unvote!(poll_item.poll_id, user_id)

    Multi.new()
    |> Multi.insert(:vote, %PollItem.Vote{poll_item_id: poll_item.id, user_id: user_id})
    |> Multi.run(:notifications, fn repo, %{vote: vote} ->
      vote = repo.preload(vote, [:user, poll_item: [poll: [post: [author: :devices]]]])
      Notifications.process_poll_vote(vote)
      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{vote: vote}} -> {:ok, vote}
      {:error, :vote, changeset, _changes} -> {:error, changeset}
    end
  end

  def unvote!(%{id: poll_id}, user_id) do
    unvote!(poll_id, user_id)
  end

  def unvote!(poll_id, user_id) do
    PollItem.Vote
    |> where(user_id: ^user_id)
    |> join(:inner, [v], pi in assoc(v, :poll_item))
    |> where([v, pi], pi.poll_id == ^poll_id)
    |> Repo.delete_all()
  end

  def create(params) do
    %Poll{}
    |> Poll.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, poll} -> {:ok, Repo.preload(poll, items: :media_files)}
      {:error, _changeset} = error -> error
    end
  end

  def add_item(poll, params) do
    params = Map.put(params, "poll_id", poll.id)

    %PollItem{}
    |> PollItem.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, item} -> {:ok, Repo.preload(item, :media_files)}
      {:error, _changeset} = error -> error
    end
  end

  def update(poll, params) do
    poll
    |> Poll.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, poll} -> {:ok, Repo.preload(poll, items: :media_files)}
      {:error, _changeset} = error -> error
    end
  end
end
