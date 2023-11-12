defmodule Web.PostCommentController do
  use Web, :controller

  alias BillBored.Post.Comments
  alias BillBored.Users

  action_fallback Web.FallbackController

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  # TODO use paths instead (comment.path = [comment.parent_ids])
  def create_child(conn, %{"id" => id} = params, user_id) do
    comment = Comments.get!(id)

    params =
      params
      |> Map.put("parent_id", id)
      |> Map.put("post_id", comment.post_id)

    create(conn, params, user_id)
  end

  #
  defp handle_vote("upvote", user, comment) do
    Comments.upvote!(comment, by: user)
  end

  defp handle_vote("downvote", user, comment) do
    Comments.downvote!(comment, by: user)
  end

  defp handle_vote("unvote", user, comment) do
    Comments.unvote!(comment, by: user)
  end

  def vote(conn, %{"id" => comment_id, "action" => action}, user_id) do
    user = Users.get_by_id(user_id)
    comment = Comments.get!(comment_id)
    handle_vote(action, user, comment)
    send_resp(conn, 204, [])
  end

  def create(conn, params, user_id) do
    with {:ok, comment} <- Comments.create_comment(params, author_id: user_id) do
      comment = Comments.load_children(comment, for_id: user_id)
      render(conn, "show.json", comment: comment)
    end
  end

  def update(conn, %{"id" => id} = params, user_id) do
    comment = Comments.get!(id)

    if comment.author_id == user_id do
      comment = Repo.preload(comment, [:interests])

      with {:ok, comment} <- Comments.update(comment, params) do
        # TODO why do we fetch the comment again here?
        comment =
          comment.id
          |> Comments.get(for_id: user_id)
          |> Repo.preload([:interests])
          |> Comments.load_children(for_id: user_id)

        render(conn, "show.json", comment: comment)
      end
    else
      send_resp(conn, 403, [])
    end
  end

  def show(conn, %{"id" => comment_id}, user_id) do
    comment =
      comment_id
      |> Comments.get!(for_id: user_id)
      |> Repo.preload([:interests])
      |> Comments.load_children(for_id: user_id)

    render(conn, "show.json", comment: comment)
  end

  def index(conn, %{"id" => post_id}, user_id) do
    %{entries: comments} = page = Comments.index_top(post_id, for_id: user_id)
    # TODO
    page = %{page | entries: Enum.map(comments, &(Comments.load_children(&1, for_id: user_id)))}
    render(conn, "index_tree.json", comments: page)
  end

  def index_childs(conn, %{"id" => id}, user_id) do
    %{entries: comments} = page = Comments.index_childs(id, for_id: user_id)
    # TODO
    page = %{page | entries: Enum.map(comments, &(Comments.load_children(&1, for_id: user_id)))}
    render(conn, "index.json", comments: page)
  end

  def index_top(conn, %{"id" => id}, user_id) do
    %{entries: comments} = page = Comments.index_top(id, for_id: user_id)
    # TODO
    page = %{page | entries: Enum.map(comments, &Comments.load_children(&1, for_id: user_id))}
    render(conn, "index.json", comments: page)
  end

  def delete(conn, %{"id" => id}, user_id) do
    comment = Comments.get!(id)

    if comment.author_id == user_id do
      Comments.delete!(comment)
      send_resp(conn, 204, [])
    else
      send_resp(conn, 403, [])
    end
  end
end
