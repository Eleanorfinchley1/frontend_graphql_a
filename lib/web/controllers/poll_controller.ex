defmodule Web.PollController do
  use Web, :controller
  alias BillBored.{Posts, Polls, PollItem}

  action_fallback Web.FallbackController

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def add_item(conn, %{"id" => poll_id} = attrs, user_id) do
    poll = Polls.get!(poll_id)
    poll = Repo.preload(poll, [:post])

    # TODO replace with BillBored.Policy.Polls policy
    if poll.post.author_id == user_id do
      attrs = Map.put(attrs, "poll_id", poll_id)

      with {:ok, _poll_item} <- Polls.add_item(poll, attrs) do
        send_resp(conn, 204, [])
      end
    else
      send_resp(conn, 403, [])
    end
  end

  def create(conn, %{"id" => post_id} = attrs, user_id) do
    post = Posts.get!(post_id)
    post = Repo.preload(post, [:author])

    # TODO replace with BillBored.Policy.Polls policy
    if post.author.id == user_id do
      attrs = Map.put(attrs, "post_id", post_id)

      with {:ok, poll} <- Polls.create(attrs) do
        render_result(conn, Web.PollView.render("show.json", poll: poll))
      end
    else
      send_resp(conn, 403, [])
    end
  end

  def show(conn, %{"id" => poll_id}, user_id) do
    poll = Polls.get!(poll_id, for_id: user_id)
    render(conn, "show.json", poll: poll)
  end

  def delete(conn, %{"id" => poll_id}, user_id) do
    poll = Polls.get!(poll_id) |> Repo.preload([:post])

    # TODO replace with BillBored.Policy.Polls policy
    if user_id == poll.post.author_id do
      Polls.delete_poll(poll.id)
      send_resp(conn, 204, [])
    else
      send_resp(conn, 403, [])
    end
  end

  def delete_item(conn, %{"id" => poll_item_id}, user_id) do
    poll_item =
      PollItem
      |> Repo.get!(poll_item_id)
      |> Repo.preload(poll: [:post])

    # TODO replace with BillBored.Policy.Polls policy
    if user_id == poll_item.poll.post.author_id do
      Polls.delete_poll_item(poll_item.id)
      send_resp(conn, 204, [])
    else
      send_resp(conn, 403, [])
    end
  end

  def update(conn, %{"id" => poll_id} = attrs, user_id) do
    old_poll = poll_id |> Polls.get!() |> Repo.preload([:post])

    # TODO replace with BillBored.Policy.Polls policy
    if user_id == old_poll.post.author_id do
      old_poll = Repo.preload(old_poll, [:items])

      with {:ok, _poll} <- Polls.update(old_poll, attrs) do
        # TODO why fetch it again?
        poll = Polls.get!(old_poll.id, for_id: user_id)
        render_result(conn, Web.PollView.render("show.json", poll: poll))
      end
    else
      send_resp(conn, 403, [])
    end
  end

  def vote(conn, %{"id" => poll_item_id}, user_id) do
    poll_item = Repo.get!(PollItem, poll_item_id)
    Polls.vote!(poll_item, user_id)
    send_resp(conn, 204, [])
  end

  def unvote_all(conn, %{"id" => poll_id}, user_id) do
    poll = Polls.get!(poll_id)
    Polls.unvote!(poll, user_id)
    send_resp(conn, 204, [])
  end
end
