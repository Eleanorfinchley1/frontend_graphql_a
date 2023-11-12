defmodule BillBored.Search do
  @moduledoc "Contains search functions"

  alias BillBored.{User, Interest, Post, Chat}
  alias Ecto.Multi

  @typep hashtagged_result :: %{posts: [Post.t()], chat_rooms: [Chat.Room.t()]}
  # @type search_field :: :usertag | :hashtag | :post_title | :post_content | :chat_room_title
  # @type searchable :: Post.t() | User.t() | Chat.Room.t()

  # TODO compare with levenshtein
  # TODO benchmark
  defmacrop similarity(lhs, rhs) do
    quote do
      fragment("similarity(?, ?)", unquote(lhs), unquote(rhs))
    end
  end

  # See https://www.postgresql.org/docs/current/static/textsearch-controls.html#TEXTSEARCH-PARSING-QUERIES
  defmacrop plainto_tsquery(query) do
    quote do
      fragment("plainto_tsquery('english', ?)", unquote(query))
    end
  end

  # See https://www.postgresql.org/docs/current/static/textsearch-controls.html#TEXTSEARCH-RANKING
  defmacrop ts_rank_cd(tsv, query) do
    quote do
      fragment("ts_rank_cd(?, ?)", unquote(tsv), unquote(query))
    end
  end

  # @doc """
  # Search over several resources at once
  # """
  # @spec search_many(String.t(), [search_field]) :: [searchable]
  # def search_many(_query, []), do: []

  # def search_many(query, [search_field | search_fields]) do
  #   import Ecto.Query

  #   # TODO limit to ~ 20
  #   # TODO maybe search over a view (needs the same structure)
  #   # TODO group by resource (chat room | user)

  #   # query
  #   # |> build_search_query(search_fields, query_for_search_field(query, search_field))
  #   # |> Repo.all()
  # end

  @spec search_all(String.t()) :: %{
          posts: [Post.t()],
          users: [User.t()],
          chat_rooms: [Chat.Room.t()],
          post_comments: [Post.Comment.t()],
          chat_room_messages: [Chat.Message.t()]
        }
  def search_all(query) do
    Multi.new()
    |> add_users_multi(query)
    |> add_posts_multi(query)
    |> add_chat_rooms_by_title_multi(query)
    |> add_hashtagged_multi(query)
    |> Repo.transaction()
    |> case do
      {:ok,
       %{
         chat_rooms_by_title: chat_rooms_by_title,
         hashtagged: %{
           chat_room_messages: chat_room_messages,
           chat_rooms: chat_rooms_hashtagged,
           post_comments: post_comments,
           posts: posts_hashtagged
         },
         posts: posts,
         users: users
       }} ->
        %{
          users: users,
          posts: (posts ++ posts_hashtagged) |> Enum.uniq_by(& &1.id),
          post_comments: post_comments,
          chat_rooms: (chat_rooms_by_title ++ chat_rooms_hashtagged) |> Enum.uniq_by(& &1.id),
          chat_room_messages: chat_room_messages
        }
    end
  end

  @spec add_users_multi(Multi.t(), String.t()) :: Multi.t()
  defp add_users_multi(multi, query) do
    Multi.run(multi, :users, fn _repo, _changes ->
      {:ok, search_users(query)}
    end)
  end

  @spec add_posts_multi(Multi.t(), String.t()) :: Multi.t()
  defp add_posts_multi(multi, query) do
    import Ecto.Query

    Multi.run(multi, :posts, fn repo, _changes ->
      posts =
        Post
        |> where([p], fragment("? @@ ?", p.tsvector, plainto_tsquery(^query)))
        # |> order_by([p], desc: ts_rank_cd(p.tsvector, plainto_tsquery(^query)))
        # |> order_by([p], desc: similarity(p.title, ^query))
        |> order_by([p], fragment("? <-> ? ASC", p.title, ^query))
        |> limit(5)
        |> repo.all()

      {:ok, posts}
    end)
  end

  @spec add_chat_rooms_by_title_multi(Multi.t(), String.t()) :: Multi.t()
  defp add_chat_rooms_by_title_multi(multi, query) do
    Multi.run(multi, :chat_rooms_by_title, fn _repo, _changes ->
      {:ok, search_chat_rooms(query)}
    end)
  end

  @spec add_hashtagged_multi(Multi.t(), String.t()) :: Multi.t()
  defp add_hashtagged_multi(multi, query) do
    Multi.run(multi, :hashtagged, fn _repo, _changes ->
      {:ok, search_by_hashtag(query)}
    end)
  end

  # @spec search_multi(String.t(), [search_field]) :: %{
  #         optional(:posts) => [Post.t()],
  #         optional(:users) => [User.t()],
  #         optional(:chat_rooms) => [Chat.Room.t()],
  #         optional(:post_comments) => [Post.Comment.t()],
  #         optional(:chat_room_messages) => [Chat.Message.t()]
  #       }
  # def search_multi(_query, []), do: %{}

  # def search_multi(query, search_fields) do
  #   Multi.new()
  #   |> maybe_add_users_multi(query, search_fields)
  #   |> maybe_add_posts_multi(query, search_fields)
  #   |> maybe_add_chat_rooms_multi(query, search_fields)
  #   |> maybe_add_hashtagged_multi(query, search_fields)
  #   |> Repo.transaction()
  #   |> case do
  #     # {:ok, %{hashtag: %{posts: posts, chat_rooms: chat_rooms}, posts: posts}} ->
  #     #   Map.take(results, search_fields_to_resources(search_fields))
  #     {:ok, results} ->
  #       results
  #       # Map.take(results, search_fields_to_resources(search_fields))
  #   end
  # end

  # @spec search_fields_to_resources([search_field]) :: [:posts | :users | :chat_rooms]
  # defp search_fields_to_resources(search_fields) do
  #   search_fields
  #   |> Enum.map(fn
  #     :usertag -> :users
  #     :hashtag -> [:posts, :chat_rooms]
  #     :post_title -> :posts
  #     :posts_content -> :posts
  #     :chat_room_title -> :chat_rooms
  #   end)
  #   |> List.flatten()
  #   |> Enum.uniq()
  # end

  # @spec maybe_add_users_multi(Multi.t(), String.t(), [search_field]) :: Multi.t()
  # defp maybe_add_users_multi(multi, query, search_fields) do
  #   if :usertag in search_fields do
  #     Multi.run(multi, :users, fn _changes ->
  #       {:ok, search_users(query)}
  #     end)
  #   else
  #     multi
  #   end
  # end

  # @spec maybe_add_chat_rooms_multi(Multi.t(), String.t(), [search_field]) :: Multi.t()
  # defp maybe_add_chat_rooms_multi(multi, query, search_fields) do
  #   if :chat_room_title in search_fields do
  #     Multi.run(multi, :chat_rooms, fn _changes ->
  #       {:ok, search_chat_rooms(query)}
  #     end)
  #   else
  #     multi
  #   end
  # end

  # @spec maybe_add_posts_multi(Multi.t(), String.t(), [search_field]) :: Multi.t()
  # defp maybe_add_posts_multi(multi, query, search_fields) do
  #   multi =
  #     if :post_title in search_fields do
  #       Multi.run(multi, :posts_by_title, fn _changes ->
  #         {:ok, search_posts(query)}
  #       end)
  #     else
  #       multi
  #     end

  #   multi =
  #     if :post_content in search_fields do
  #       Multi.run(multi, :posts_by_content, fn _changes ->
  #         {:ok, search_posts_content(query)}
  #       end)
  #     else
  #       multi
  #     end

  #   Multi.run(multi, :posts, fn
  #     %{
  #       posts_by_title: posts_by_title,
  #       posts_by_content: posts_by_content
  #     } ->
  #       posts = (posts_by_title ++ posts_by_content) |> Enum.uniq_by(fn post -> post.id end)
  #       {:ok, posts}

  #     %{posts_by_title: posts_by_title} ->
  #       {:ok, posts_by_title}

  #     %{posts_by_content: posts_by_content} ->
  #       {:ok, posts_by_content}

  #     _ ->
  #       {:ok, []}
  #   end)
  # end

  # @spec maybe_add_hashtagged_multi(Multi.t(), String.t(), [search_field]) :: Multi.t()
  # defp maybe_add_hashtagged_multi(multi, query, search_fields) do
  #   if :hashtag in search_fields do
  #     Multi.run(multi, :hashtag, fn _changes ->
  #       {:ok, search_by_hashtag(query)}
  #     end)
  #   else
  #     multi
  #   end
  # end

  # @spec build_search_query(String.t(), [search_field], Ecto.Query.t()) :: Ecto.Query.t()
  # defp build_search_query(_search_query, [], acc_query), do: acc_query

  # defp build_search_query(search_query, [search_field | rest_search_fields], acc_query) do
  #   build_search_query(search_query, rest_search_fields, acc_query)
  # end

  # @spec query_for_search_field(String.t(), search_field) :: Ecto.Query.t()
  # defp query_for_search_field(query, search_field) do
  #   case search_field do
  #     :usertag ->
  #       users_username_query(query, 0.3)

  #     # :hashtag ->

  #     :post_title ->
  #       posts_title_query(query, 0.3)

  #     :post_content ->
  #       posts_content_query(query)

  #     :dropchat_title ->
  #       dropchats_title_query(query, 0.3)
  #   end
  # end

  # TODO limit count to ~20
  @doc """
  Search through users by their username
  """
  @spec search_users(String.t(), pos_integer, float) :: [User.t()]
  def search_users(query, count \\ 10, similarity_limit \\ 0.2) do
    import Ecto.Query

    distance = 1.0 - similarity_limit

    users_query =
      User
      |> order_by([u], asc: fragment("? <-> ? ASC", u.username, ^query))
      |> limit(^count)

    from(u in subquery(users_query),
      where: fragment("? <-> ? < ?", u.username, ^query, ^distance)
    )
    |> Repo.all()
  end

  @doc """
  Search through posts by their title
  """
  @spec search_posts(String.t()) :: [Post.t()]
  @spec search_posts(String.t(), float) :: [Post.t()]
  def search_posts(query, limit \\ 0.3) do
    import Ecto.Query

    query
    |> posts_title_query(limit)
    |> where([p], not p.private?)
    |> Repo.all()
  end

  @doc """
  Search through posts by their content (pst_post.body)
  """
  @spec search_posts_content(String.t()) :: [Post.t()]
  def search_posts_content(query) do
    import Ecto.Query

    query
    |> posts_content_query()
    |> where([p], not p.private?)
    |> Repo.all()
  end

  @doc """
  Search through chat rooms by their title
  """
  @spec search_chat_rooms(String.t()) :: [Chat.Room.t()]
  @spec search_chat_rooms(String.t(), float) :: [Chat.Room.t()]
  def search_chat_rooms(query, limit \\ 0.3) do
    import Ecto.Query

    # TODO location not nil?
    # TODO tsv

    query
    |> chat_rooms_title_query(limit)
    |> where([r], not r.private)
    |> Repo.all()
  end

  # TODO give more weight to resources which are geographically close to the user
  # TODO limit count to ~20
  # TODO sort by timestamp / id?
  @doc """
  Search through posts and chat rooms by their associated hashtags (interests)
  """
  @spec search_by_hashtag(String.t()) :: hashtagged_result
  @spec search_by_hashtag(String.t(), float) :: hashtagged_result
  def search_by_hashtag(query, limit \\ 0.3) do
    query = Interest.normalize(query)

    import Ecto.Query

    Multi.new()
    |> Multi.run(:interests, fn repo, _changes ->
      interests =
        query
        |> interest_query(limit)
        |> where([i], not i.disabled?)
        |> repo.all()

      {:ok, interests}
    end)
    |> Multi.run(:found_interest_ids, fn _repo, %{interests: interests} ->
      {:ok, Enum.map(interests, & &1.id)}
    end)
    |> Multi.run(:chat_rooms, fn
      _repo, %{found_interest_ids: []} ->
        {:ok, []}

      # TODO
      repo, %{found_interest_ids: found_interest_ids} ->
        chat_rooms =
          Chat.Room
          |> where([r], r.interest_id in ^found_interest_ids)
          |> where([r], not r.private)
          |> distinct(true)
          |> repo.all()

        {:ok, chat_rooms}
    end)
    |> Multi.run(:posts, fn
      _repo, %{found_interest_ids: []} ->
        {:ok, []}

      repo, %{found_interest_ids: found_interest_ids} ->
        posts =
          Post.Interest
          |> where([ph], ph.interest_id in ^found_interest_ids)
          |> join(:left, [ph], p in Post, on: p.id == ph.post_id)
          |> where([ph, p], not p.private?)
          |> distinct(true)
          |> select([ph, p], p)
          |> repo.all()

        {:ok, posts}
    end)
    |> Multi.run(:post_comments, fn
      _repo, %{found_interest_ids: []} ->
        {:ok, []}

      repo, %{found_interest_ids: found_interest_ids} ->
        post_comments =
          Post.Comment.Interest
          |> where([ch], ch.interest_id in ^found_interest_ids)
          |> join(:left, [ch], c in Post.Comment, on: c.id == ch.comment_id)
          |> join(:left, [ch, c], p in Post, on: p.id == c.post_id)
          |> where([ch, c, p], not p.private?)
          |> distinct(true)
          |> select([ch, c, p], %{c | post: p})
          |> repo.all()

        {:ok, post_comments}
    end)
    |> Multi.run(:chat_room_messages, fn
      _repo, %{found_interest_ids: []} ->
        {:ok, []}

      repo, %{found_interest_ids: found_interest_ids} ->
        chat_room_messages =
          Chat.Message.Interest
          |> where([mh], mh.interest_id in ^found_interest_ids)
          |> join(:left, [mh], m in Chat.Message, on: m.id == mh.message_id)
          |> join(:left, [mh, m], r in Chat.Room, on: r.id == m.room_id)
          |> where([mh, m, r], not r.private)
          |> distinct(true)
          |> select([mh, m, r], %{m | room: r})
          |> repo.all()

        {:ok, chat_room_messages}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, resp} ->
        Map.take(resp, [:posts, :chat_rooms, :post_comments, :chat_room_messages])
    end
  end

  @spec users_username_query(String.t(), float) :: Ecto.Query.t()
  def users_username_query(query, limit) do
    import Ecto.Query

    distance = 1.0 - limit

    User
    |> where([u], fragment("? <-> ? < ?", u.username, ^query, ^distance))
    |> order_by([u], asc: fragment("? <-> ?", u.username, ^query))
  end

  @spec interest_query(String.t(), float) :: Ecto.Query.t()
  def interest_query(query, limit) do
    import Ecto.Query

    Interest
    |> where([i], similarity(i.hashtag, ^query) > ^limit)
    |> order_by([i], desc: similarity(i.hashtag, ^query))
  end

  @spec posts_title_query(String.t(), float) :: Ecto.Query.t()
  def posts_title_query(query, limit) do
    import Ecto.Query

    Post
    |> where([p], similarity(p.title, ^query) > ^limit)
    |> order_by([p], desc: similarity(p.title, ^query))
  end

  @spec posts_content_query(String.t()) :: Ecto.Query.t()
  def posts_content_query(query) do
    import Ecto.Query

    Post
    |> where([p], fragment("? @@ ?", p.tsvector, plainto_tsquery(^query)))
    |> order_by([p], desc: ts_rank_cd(p.tsvector, plainto_tsquery(^query)))
  end

  @spec chat_rooms_title_query(String.t(), float) :: Ecto.Query.t()
  def chat_rooms_title_query(query, limit) do
    import Ecto.Query

    Chat.Room
    |> where([r], similarity(r.title, ^query) > ^limit)
    |> order_by([r], desc: similarity(r.title, ^query))
  end

  # @spec union_query([Ecto.Query.t()]) :: sql :: String.t()
  # def union_query([]), do: ""

  # def union_query([query | queries]) do
  #   elem(Repo.to_sql(:all, query), 0) <> "UNION" <> union_query(queries)
  # end
end
