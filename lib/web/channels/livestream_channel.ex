defmodule Web.LivestreamChannel do
  use Web, :channel

  import BillBored.Helpers, only: [humanize_errors: 1]
  import Web.LivestreamView, only: [render: 2]
  import Ecto.Query

  require Logger

  alias BillBored.{User, Livestreams, Livestream}
  alias BillBored.Livestream.{Vote, View}
  alias BillBored.Livestream.Comment.Vote, as: C_Vote

  def join("livestream:" <> <<livestream_id::36-bytes>>, _params, socket) do
    livestream_id
    |> BillBored.Livestreams.get()
    |> check_and_join_livestream(socket)
  end

  def handle_info({:after_join, livestream_id}, socket) do
    updated_views = %{
      online_viewers_count: BillBored.Livestreams.InMemory.get(:viewers_count, livestream_id),
      views_count:
        View |> where(livestream_id: ^livestream_id) |> select([v], count()) |> Repo.one()
    }

    broadcast(socket, "livestream_join", updated_views)
    {:noreply, socket}
  end

  def check_and_join_livestream(
        %Livestream{recorded?: true, owner_id: owner_id, id: livestream_id},
        %{assigns: %{user: %User{id: user_id}}} = socket
      )
      when owner_id == user_id do
    BillBored.Livestreams.check_and_create_view(user_id, livestream_id)

    socket =
      socket
      |> assign(:livestream_id, livestream_id)
      |> assign(:owner?, true)

    send(self(), {:after_join, livestream_id})
    {:ok, socket}
  end

  def check_and_join_livestream(
        %Livestream{recorded?: true, id: livestream_id},
        %{assigns: %{user: %User{id: user_id}}} = socket
      ) do
    BillBored.Livestreams.check_and_create_view(user_id, livestream_id)

    socket =
      socket
      |> assign(:livestream_id, livestream_id)
      |> assign(:owner?, false)

    send(self(), {:after_join, livestream_id})
    {:ok, socket}
  end

  def check_and_join_livestream(
        %Livestream{owner_id: owner_id, id: livestream_id} = livestream,
        %{assigns: %{user: %User{id: user_id}}} = socket
      )
      when owner_id == user_id do
    BillBored.Livestreams.check_and_create_view(user_id, livestream_id)

    socket =
      socket
      |> assign(:livestream_id, livestream_id)
      |> assign(:owner?, true)

    BillBored.Livestreams.InMemory.start(livestream)
    send(self(), {:after_join, livestream_id})
    {:ok, socket}
  end

  def check_and_join_livestream(
        %Livestream{id: livestream_id},
        %{assigns: %{user: %User{id: user_id}}} = socket
      ) do
    case BillBored.Livestreams.InMemory.exists?(livestream_id) do
      true ->
        BillBored.Livestreams.check_and_create_view(user_id, livestream_id)
        join_livestream(livestream_id, socket)

      _ ->
        {:error, %{"detail" => "active livestream does not exist"}}
    end
  end

  def check_and_join_livestream(_l, _s), do: {:error, %{"detail" => "livestream not found"}}

  defp join_livestream(<<livestream_id::36-bytes>>, socket) do
    new_viewers_count = BillBored.Livestreams.InMemory.update_viewers_count(livestream_id, +1)

    socket =
      socket
      |> assign(:livestream_id, livestream_id)
      |> assign(:owner?, false)

    send(self(), {:after_join, livestream_id})
    {:ok, %{"viewers_count" => new_viewers_count}, socket}
  end

  def handle_in(
        "comment:new",
        params,
        %{assigns: %{user: %User{id: author_id} = author, livestream_id: livestream_id}} = socket
      ) do
    case Livestreams.create_comment(params, livestream_id: livestream_id, author_id: author_id) do
      {:ok, %Livestream.Comment{} = comment} ->
        broadcast!(
          socket,
          "comment:new",
          render("comment.json", %{comment: comment, author: author})
        )

        {:reply, :ok, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, humanize_errors(changeset)}, socket}
    end
  end

  def handle_in(
        "comments:list",
        _params,
        %{
          assigns: %{livestream_id: livestream_id, user: %User{id: user_id} = _user}
        } = socket
      ) do
    comments = Livestreams.comments_list_with_votes(livestream_id, user_id)
    {:reply, {:ok, %{comments: comments}}, socket}
  end

  def handle_in(
        "comment_vote:new",
        %{"comment_id" => comment_id, "vote_type" => v_type},
        %{assigns: %{user: %User{id: user_id}}} = socket
      ) do
    case Livestreams.create_or_update_comment_vote(user_id, comment_id, v_type) do
      :ok ->
        broadcast!(
          socket,
          "comment:change_votes",
          %{
            comment_id: comment_id,
            upvotes: comment_votes(comment_id, "upvote"),
            downvotes: comment_votes(comment_id, "downvote")
          }
        )

        {:reply, :ok, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, humanize_errors(changeset)}, socket}

      {:error, _reason} = error ->
        error
    end
  end

  def handle_in(
        "vote:new",
        %{"vote_type" => v_type},
        %{assigns: %{user: %User{id: user_id} = _user, livestream_id: livestream_id}} = socket
      ) do
    case Livestreams.create_or_update_vote(user_id, livestream_id, v_type) do
      :ok ->
        broadcast!(
          socket,
          "change_votes",
          %{
            upvotes: livestream_votes(livestream_id, "upvote"),
            downvotes: livestream_votes(livestream_id, "downvote")
          }
        )

        {:reply, :ok, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, humanize_errors(changeset)}, socket}

      {:error, _reason} = error ->
        error
    end
  end

  def handle_in(
        "livestream:info",
        _params,
        %{assigns: %{user: %User{id: user_id} = _user, livestream_id: livestream_id}} = socket
      ) do
    reply = %{
      online_viewers_count: BillBored.Livestreams.InMemory.get(:viewers_count, livestream_id),
      views_count:
        View |> where(livestream_id: ^livestream_id) |> select([v], count()) |> Repo.one(),
      upvotes: livestream_votes(livestream_id, "upvote"),
      downvotes: livestream_votes(livestream_id, "downvote"),
      current_user_votes: current_user_votes(livestream_id, user_id)
    }

    {:reply, {:ok, reply}, socket}
  end

  def terminate(_reason, %{assigns: %{owner?: owner?, livestream_id: livestream_id}}) do
    case owner? do
      true -> BillBored.Livestreams.InMemory.publish_done(livestream_id)
      false -> BillBored.Livestreams.InMemory.update_viewers_count(livestream_id, -1)
    end

    :ok
  end

  def terminate(_reason, _socket) do
    :ok
  end

  def current_user_votes(l_id, current_u_id) do
    upvote = "upvote"
    downvote = "downvote"

    Livestream
    |> where(id: ^l_id)
    |> join(:left, [c], v in assoc(c, :votes))
    |> group_by([c, v], c.id)
    |> select([c, v], %{
      upvote:
        count(
          fragment(
            "case (? = ? and ? = ?) when true then 1 else null end",
            v.vote_type,
            ^upvote,
            v.user_id,
            ^current_u_id
          )
        ),
      downvote:
        count(
          fragment(
            "case (? = ? and ? = ?) when true then 1 else null end",
            v.vote_type,
            ^downvote,
            v.user_id,
            ^current_u_id
          )
        )
    })
    |> Repo.all()
  end

  def livestream_votes(livestream_id, vote_type) do
    Vote
    |> where(livestream_id: ^livestream_id)
    |> where(vote_type: ^vote_type)
    |> select([v], count())
    |> Repo.one()
  end

  def comment_votes(comment_id, vote_type) do
    C_Vote
    |> where(comment_id: ^comment_id)
    |> where(vote_type: ^vote_type)
    |> select([v], count())
    |> Repo.one()
  end
end
