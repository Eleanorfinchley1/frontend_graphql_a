defmodule BillBored.Post.Comments do
  import Ecto.Query
  import Ecto.Changeset, only: [put_assoc: 3, add_error: 3]
  alias Ecto.Multi

  alias BillBored.{User, Users, Interests, Posts}
  alias BillBored.Post.Comment
  alias Comment.{Upvote, Downvote}

  require Logger

  def get(id, opts \\ []) do
    user_id = opts[:for_id] || (opts[:for] && opts[:for].id)

    Comment.available(opts)
    |> where(id: ^id)
    |> add_statistics(user_id || -1, [id])
    |> preload(:media_files)
    |> Repo.one()
    |> BillBored.Helpers.normalize()
  end

  def get!(id, opts \\ []) do
    user_id = opts[:for_id] || (opts[:for] && opts[:for].id)

    Comment.available(opts)
    |> where(id: ^id)
    |> add_statistics(user_id || -1, [id])
    |> preload(:media_files)
    |> Repo.one!()
    |> BillBored.Helpers.normalize()
  end

  def load_children(%Comment{} = comment, opts \\ []) do
    descendants =
      comment
      |> Comment.descendants()
      |> maybe_hide_body(opts)
      |> order_by([c], asc: c.parent_id, asc: c.id)
      |> Repo.all()
      |> Repo.preload([:interests, :author, :media_files])

    arrange_descendants(comment, descendants)
  end

  defp arrange_descendants(comment, descendants) do
    with {arranged_comment, [], _} <-
           do_arrange_descendants(descendants, %{comment | children: []}, [], false) do
      arranged_comment
    else
      _ ->
        raise RuntimeError, "Failed to arrange descendants of comment #{comment.id}"
    end
  end

  defp do_arrange_descendants(
         [%{parent_id: parent_id} = comment | rest],
         %{id: parent_id, children: children} = tree,
         siblings,
         valid_subtree
       ) do
    {subtree, new_rest, subtree_valid_subtree} =
      do_arrange_descendants(rest, %{comment | children: []}, [], false)

    case subtree do
      %Comment{blocked?: true, children: []} ->
        do_arrange_descendants(new_rest, tree, siblings, valid_subtree)

      %Comment{blocked?: true} ->
        if subtree_valid_subtree do
          do_arrange_descendants(
            new_rest,
            %{tree | children: [subtree | children]},
            siblings,
            true
          )
        else
          do_arrange_descendants(new_rest, tree, siblings, valid_subtree)
        end

      _ ->
        do_arrange_descendants(new_rest, %{tree | children: [subtree | children]}, siblings, true)
    end
  end

  defp do_arrange_descendants(
         [%{parent_id: parent_id} = sibling | rest],
         %{parent_id: parent_id} = tree,
         siblings,
         true
       ) do
    do_arrange_descendants(rest, tree, [sibling | siblings], true)
  end

  defp do_arrange_descendants(
         [%{parent_id: parent_id} = sibling | rest],
         %{parent_id: parent_id} = tree,
         siblings,
         false
       ) do
    if sibling.blocked? do
      do_arrange_descendants(rest, tree, [sibling | siblings], false)
    else
      do_arrange_descendants(rest, tree, [sibling | siblings], true)
    end
  end

  defp do_arrange_descendants(rest, tree, siblings, true) do
    {tree, siblings ++ rest, true}
  end

  defp do_arrange_descendants(rest, tree, siblings, false) do
    has_valid = Enum.any?(rest, &(!&1.blocked?))
    {tree, siblings ++ rest, has_valid}
  end

  defp count_q(module, ids) do
    module
    |> where([d], d.comment_id in ^ids)
    |> group_by([d], d.comment_id)
    |> select([d], %{comment_id: d.comment_id, count: count(d.id)})
  end

  defp count_q(module, ids, user_id) do
    module
    |> where([d], d.user_id == ^user_id)
    |> where([d], d.comment_id in ^ids)
    |> group_by([d], d.comment_id)
    |> select([d], %{comment_id: d.comment_id, count: count(d.id)})
  end

  defp add_statistics(comment_query, user_id, ids) do
    comment_query
    |> join(:left, [p], u in subquery(count_q(Upvote, ids)), on: p.id == u.comment_id)
    |> join(:left, [p], d in subquery(count_q(Downvote, ids)), on: p.id == d.comment_id)
    |> join(:left, [p], uu in subquery(count_q(Upvote, ids, user_id)), on: p.id == uu.comment_id)
    |> join(:left, [p], ud in subquery(count_q(Downvote, ids, user_id)), on: p.id == ud.comment_id)
    |> select([p, ..., u, d, uu, ud], %{
      p
      | downvotes_count: d.count,
        upvotes_count: u.count,
        user_upvoted?: uu.count > 0,
        user_downvoted?: ud.count > 0
    })
  end

  defp maybe_hide_body(queryable, %{for: %User{id: for_id}}) do
    maybe_hide_body(queryable, %{for_id: for_id})
  end

  defp maybe_hide_body(queryable, for_id: for_id) do
    maybe_hide_body(queryable, %{for_id: for_id})
  end

  defp maybe_hide_body(queryable, %{for_id: for_id}) do
    Comment.join_blocked(queryable, for_id)
    |> join(:left, [q], assoc(q, :author), as: :author)
    |> select_merge([blocked: bl, author: a], %{
      body:
        fragment("(CASE WHEN ? THEN '' ELSE body END)", a.banned? == true or a.deleted? == true or not is_nil(bl.id)),
      blocked?: a.banned? == true or a.deleted? == true or not is_nil(bl.id)
    })
  end

  defp maybe_hide_body(queryable, _) do
    queryable
    |> join(:left, [q], assoc(q, :author), as: :author)
    |> select_merge([author: a], %{
      body: fragment("(CASE WHEN ? THEN '' ELSE body END)", a.banned? == true or a.deleted? == true),
      blocked?: a.banned? == true or a.deleted? == true
    })
  end

  @spec upvote!(Comment.t(), by: User.t()) :: Comment.Upvote.t()
  def upvote!(%Comment{} = comment, by: %User{} = user) do
    # TODO why is this necessary?
    unvote!(comment, by: user)
    upvote = Repo.insert!(%Comment.Upvote{comment: comment, user: user})

    unless comment.author_id == user.id do
      Notifications.process_post_comment_upvote(%{
        upvote
        | comment: Repo.preload(comment, author: [:devices])
      })
    end

    upvote
  end

  @spec downvote!(Comment.t(), by: User.t()) :: Comment.Downvote.t()
  def downvote!(%Comment{} = comment, by: %User{} = user) do
    # TODO why is this necessary?
    unvote!(comment, by: user)
    downvote = Repo.insert!(%Comment.Downvote{comment: comment, user: user})

    Notifications.process_post_comment_downvote(%{
      downvote
      | comment: Repo.preload(comment, :author)
    })

    downvote
  end

  @spec unvote!(Comment.t(), by: User.t()) :: :ok
  def unvote!(comment, by: user) do
    from(a in Comment.Upvote, where: a.user_id == ^user.id and a.comment_id == ^comment.id)
    |> Repo.delete_all()

    from(a in Comment.Downvote, where: a.user_id == ^user.id and a.comment_id == ^comment.id)
    |> Repo.delete_all()

    :ok
  end

  defp index(query, params) do
    ids =
      query
      |> select([c], c.id)
      |> Repo.all()

    user_id = params[:for_id] || (params[:for] && params[:for].id)

    result =
      query
      |> preload([:author, :media_files, :interests, author: :interests_interest])
      |> add_statistics(user_id, ids)
      |> Repo.paginate()

    put_in(result.entries, Enum.map(result.entries, &BillBored.Helpers.normalize/1))
  end

  def index_childs(parent_id, params \\ []) do
    query =
      Comment.available(params)
      |> where([c], c.parent_id == ^parent_id)

    index(query, params)
  end

  def index_top(post_id, params \\ []) do
    query =
      Comment.available(params)
      |> where([c], c.post_id == ^post_id)
      |> where([c], is_nil(c.parent_id))

    index(query, params)
  end

  def delete(comment) do
    Repo.delete(comment)
  end

  def delete!(comment) do
    Repo.delete!(comment)
  end

  def insert_or_update(comment, attrs) do
    Ecto.Multi.new()
    |> interests_multi(attrs["interests"] || [])
    |> Ecto.Multi.run(:comments, fn repo, %{interests: tags} ->
      comment
      |> Comment.changeset(attrs)
      |> put_assoc(:interests, tags)
      |> repo.insert_or_update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, map} ->
        {:ok, map[:comments]}

      {:error, :interests, msgs, _changes} ->
        changeset =
          comment
          |> Comment.changeset(attrs)
          |> add_error(:interests, Enum.join(msgs, "; "))

        {:error, changeset}

      {:error, :comments, changeset, _changes} ->
        {:error, changeset}
    end
  end

  defp interests_multi(multi, interests) do
    Multi.run(multi, :interests, fn _repo, _changes ->
      Interests.insert_and_get_back(interests)
    end)
  end

  def create_comment(attrs, author_id: author_id) do
    Multi.new()
    |> interests_multi(attrs["interests"] || [])
    |> Multi.insert(:comment, fn %{interests: tags} ->
      %Comment{author_id: author_id}
      |> Comment.changeset(attrs)
      |> put_assoc(:interests, tags)
    end)
    |> Multi.run(:notifications, fn repo, %{comment: comment} ->
      %{post: post} = comment = repo.preload(comment, [:author, post: [author: :devices]])

      unless author_id == post.author_id do
        Notifications.process_post_comment(comment)
      end

      if Posts.new_popular_post?(post) do
        receivers = Users.list_users_located_around_location(post.location)
        Notifications.process_popular_post(post: post, receivers: receivers)
        :ok = Posts.mark_popular_post_notified(post.id)
      end

      {:ok, nil}
    end)
    |> Repo.transaction()
    # TODO no need to use case, just return what Repo.transaction returns
    |> case do
      {:ok, %{comment: comment}} ->
        {:ok, comment}

      # TODO remove
      {:error, :interests, msgs, _changes} ->
        changeset =
          %Comment{author_id: author_id}
          |> Comment.changeset(attrs)
          |> add_error(:interests, Enum.join(msgs, "; "))

        {:error, changeset}

      {:error, :comment, changeset, _changes} ->
        {:error, changeset}
    end
  end

  def update(comment, attrs \\ %{}) do
    insert_or_update(comment, attrs)
  end

  # defmacrop downvotes_count(comment_id) do
  #   quote do
  #     fragment(
  #       "SELECT count(id) AS count FROM posts_comments_downvotes WHERE comment_id = ?",
  #       unquote(comment_id)
  #     )
  #   end
  # end

  # defmacrop upvotes_count(comment_id) do
  #   quote do
  #     fragment(
  #       "SELECT count(id) AS count FROM posts_comments_upvotes WHERE comment_id = ?",
  #       unquote(comment_id)
  #     )
  #   end
  # end
end
