defmodule BillBored.Posts do
  use Bitwise, only_operators: true

  import Ecto.Query
  import Geo.PostGIS, only: [st_dwithin_in_meters: 3, st_covered_by: 2]
  import BillBored.ServiceRegistry, only: [service: 1]

  @typep post_types :: [:event | :vote | :regular | :poll]

  @fields [
    :media_files,
    :interests,
    :business,
    :business_admin,
    :business_offer,
    :admin_author,
    events: [:media_files, :attendees, place: :types],
    author: [:interests_interest],
    polls: [items: :media_files],
    place: :types
  ]

  @default_page_size 30

  alias BillBored.{Post, Posts, User, Users, Interests, Events, Polls}
  alias BillBored.Post.{Comment, Upvote, Downvote}

  alias BillBored.Post.Interest, as: PostInterest

  alias Ecto.Multi

  import Ecto.Changeset, only: [put_assoc: 3, add_error: 3]

  # import BillBored.Geo, only: [fake_place: 1]

  require Logger

  # def get_post_by_id(id), do: get(id)

  def get!(id, opts \\ [preload: @fields]) do
    fields = opts[:preload] || @fields
    user_id = opts[:for_id] || (opts[:for] && opts[:for].id)

    post =
      Post.available(opts)
      |> where(id: ^id)
      |> preload(^fields)
      |> Repo.one!()
      |> add_statistics(for_id: user_id || -1)

    if opts[:for_id] || opts[:for] do
      post
    else
      %{post | user_upvoted?: nil, user_downvoted?: nil}
    end
  end

  def get_for_business(business_id, id) do
    case from(p in Post, where: p.id == ^id and p.business_id == ^business_id) |> Repo.one() do
      %Post{} = post -> {:ok, post}
      _ -> {:error, :not_found}
    end
  end

  def insert_or_update(post, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:interests, fn _repo, _ ->
      Interests.insert_and_get_back(attrs["interests"] || [])
    end)
    |> Ecto.Multi.run(:posts, fn repo, %{interests: tags} ->
      post
      |> Post.changeset(attrs)
      |> put_assoc(:interests, tags)
      |> repo.insert_or_update()
    end)
    |> Ecto.Multi.run(:notifications, fn _repo, %{posts: post} ->
      service(BillBored.CachedPosts).invalidate_post(post)

      if is_list(post.events) do
        Enum.each(post.events, fn event ->
          event = %{event | post: post}
          receivers = Events.list_interested_nearby_users(event)
          Notifications.process_matching_event_interests(event: event, receivers: receivers)
        end)
      end

      {:ok, nil}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, map} ->
        {:ok, map[:posts]}

      {:error, :interests, msgs, _changes} ->
        changeset =
          post
          |> Post.changeset(attrs)
          |> add_error(:interests, Enum.join(msgs, "; "))

        {:error, changeset}

      {:error, :posts, changeset, _changes} ->
        {:error, changeset}
    end
  end

  def request_business_post_approval(post_id, approver_id, requester_id) do
    Multi.new()
    |> Multi.run(:ensure_new_request, fn repo, _changes ->
      if repo.get_by(Post.ApprovalRequest,
           post_id: post_id,
           approver_id: approver_id,
           requester_id: requester_id
         ) do
        {:error, :already_exists}
      else
        {:ok, nil}
      end
    end)
    |> verify_post_multi(post_id)
    |> verify_approver_membership_multi(approver_id)
    |> Multi.run(:request, fn repo,
                              %{
                                post: %Post{id: post_id},
                                approver_membership: %User.Membership{member_id: approver_id}
                              } ->
      repo.insert(%Post.ApprovalRequest{
        post_id: post_id,
        approver_id: approver_id,
        requester_id: requester_id
      })
    end)
    |> Multi.run(:notifications, fn repo, %{request: request} ->
      request
      |> repo.preload([:requester, approver: :devices])
      |> Notifications.process_post_approval_request()

      {:ok, nil}
    end)
    |> Repo.transaction()
  end

  defp approver_membership(business_id, approver_id) do
    User.Membership
    |> where([m], m.business_account_id == ^business_id and m.member_id == ^approver_id)
    |> Repo.one()
  end

  defp verify_approver_membership_multi(multi, approver_id) do
    Multi.run(multi, :approver_membership, fn _repo, %{post: %Post{business_id: business_id}} ->
      case approver_membership(business_id, approver_id) do
        %User.Membership{role: role} = membership when role in ["admin", "owner"] ->
          {:ok, membership}

        %User.Membership{role: role} when role not in ["admin", "owner"] ->
          {:error, :invalid_role}

        nil ->
          {:error, :not_found}
      end
    end)
  end

  defp verify_post_multi(multi, post_id) do
    Multi.run(multi, :post, fn repo, _changes ->
      case Post |> repo.get(post_id) |> repo.preload([:business]) do
        %Post{business: %User{}, approved?: false} = post -> {:ok, post}
        %Post{business: nil} -> {:error, :not_business_post}
        %Post{approved?: true} -> {:error, :already_approved}
        nil -> {:error, :not_found}
      end
    end)
  end

  defp get_approve_request_multi(multi, post_id, approver_id, requester_id) do
    Multi.run(multi, :request, fn repo, _changes ->
      case repo.get_by(Post.ApprovalRequest,
             post_id: post_id,
             approver_id: approver_id,
             requester_id: requester_id
           ) do
        %Post.ApprovalRequest{} = request -> {:ok, request}
        nil -> {:error, :not_found}
      end
    end)
  end

  def approve_business_post(post_id, approver_id, requester_id) do
    Multi.new()
    |> get_approve_request_multi(post_id, approver_id, requester_id)
    # TODO if the post is invalid -> delete request
    |> verify_post_multi(post_id)
    # TODO if membership is invalid -> delete request
    |> verify_approver_membership_multi(approver_id)
    |> Multi.run(:cleanup, fn _repo, %{request: request} ->
      :ok = cleanup_approve_request(request)
      {:ok, nil}
    end)
    |> Multi.run(:approved_post, fn repo, %{post: post} ->
      post
      |> Ecto.Changeset.change(%{approved?: true})
      |> repo.update()
      |> case do
        {:ok, post} -> {:ok, repo.preload(post, :media_files)}
        {:error, _changeset} = error -> error
      end
    end)
    |> Repo.transaction()
  end

  def reject_business_post(post_id, approver_id, requester_id, note) do
    Multi.new()
    |> get_approve_request_multi(post_id, approver_id, requester_id)
    # TODO if the post is invalid -> delete request
    |> verify_post_multi(post_id)
    # TODO if membership is invalid -> delete request
    |> verify_approver_membership_multi(approver_id)
    |> Multi.run(:rejection, fn repo,
                                %{
                                  request: %Post.ApprovalRequest{
                                    post_id: post_id,
                                    approver_id: approver_id,
                                    requester_id: requester_id
                                  }
                                } ->
      # TODO think how to handle duplicate rejection notifications
      %Post.ApprovalRequest.Rejection{
        post_id: post_id,
        approver_id: approver_id,
        requester_id: requester_id
      }
      |> Post.ApprovalRequest.Rejection.changeset(%{note: note})
      |> repo.insert(
        on_conflict: [set: [note: note]],
        conflict_target: [:post_id, :approver_id, :requester_id],
        returning: true
      )
    end)
    |> Multi.run(:cleanup, fn repo, %{request: request} ->
      {:ok, repo.delete!(request)}
    end)
    |> Multi.run(:notifications, fn repo, %{rejection: rejection} ->
      rejection
      |> repo.preload([:approver, requester: :devices])
      |> Notifications.process_post_approval_request_rejection()

      {:ok, nil}
    end)
    |> Repo.transaction()
  end

  defp cleanup_approve_request(%Post.ApprovalRequest{} = request) do
    Repo.delete!(request)

    Post.ApprovalRequest.Rejection
    |> where(
      post_id: ^request.post_id,
      approver_id: ^request.approver_id,
      requester_id: ^request.requester_id
    )
    |> Repo.delete_all()

    :ok
  end

  def update(post, attrs \\ %{}) do
    insert_or_update(post, attrs)
  end

  def delete(post_id) do
    post = Posts.get!(post_id)
    service(BillBored.CachedPosts).invalidate_post(post)
    Repo.delete(post)
  end

  @spec upvote!(Post.t(), by: User.t()) :: Post.Upvote.t()
  def upvote!(%Post{} = post, by: %User{} = user) do
    # TODO why is this necessary?
    unvote!(post, by: user)
    upvote = Repo.insert!(%Post.Upvote{post: post, user: user})

    unless post.author_id == user.id do
      Notifications.process_post_upvote(%{upvote | post: Repo.preload(post, author: :devices)})
    end

    upvote
  end

  @spec downvote!(Post.t(), by: User.t()) :: Post.Downvote.t()
  def downvote!(%Post{} = post, by: %User{} = user) do
    unvote!(post, by: user)
    downvote = Repo.insert!(%Post.Downvote{post: post, user: user})

    unless post.author_id == user.id do
      Notifications.process_post_downvote(downvote)
    end

    downvote
  end

  @spec unvote!(Post.t(), by: User.t()) :: :ok
  def unvote!(post, by: user) do
    from(a in Post.Upvote, where: a.user_id == ^user.id and a.post_id == ^post.id)
    |> Repo.delete_all()

    from(a in Post.Downvote, where: a.user_id == ^user.id and a.post_id == ^post.id)
    |> Repo.delete_all()

    :ok
  end

  # defmacrop valid_event_date(post_id) do
  #   quote do
  #     fragment(
  #       "(SELECT max(begin_date) FROM events WHERE post_id = ?) > (now() - interval '12 hours')",
  #       unquote(post_id)
  #     )
  #   end
  # end

  defmacrop abs_date_diff_from_now(date) do
    quote do
      fragment("@extract(epoch from ? - (now() at time zone 'utc'))", unquote(date))
    end
  end

  def list_by_location(geometry, filter \\ [], pagination_options \\ []) do
    ids =
      if filter[:for_id] do
        ids_by_location(geometry, filter[:for_id])
      else
        ids_by_location(geometry)
      end

    Post.available(filter)
    # |> distinct(true)
    |> where([p], p.id in ^ids)
    |> where([p], p.approved?)
    |> join(:left, [p], e in BillBored.Event, on: e.post_id == p.id, as: :events)
    |> where([p, events: e], p.inserted_at > ago(1, "day") or e.other_date > ago(12, "hour"))
    |> post_type_filter(filter[:types] || [:event, :poll, :regular, :vote])
    # TODO find a cleaner way
    |> where(^dynamic_post_filter(filter))
    |> add_statistics(ids, filter[:for_id] || -1)
    |> order_by([p, events: e],
      asc: abs_date_diff_from_now(e.date),
      asc: abs_date_diff_from_now(p.inserted_at)
    )
    |> preload([
      :media_files,
      :interests,
      :author,
      :admin_author,
      :business,
      :business_admin,
      polls: [items: :media_files],
      place: :types,
      events: [:media_files, :attendees, place: :types]
    ])
    |> Repo.paginate(pagination_options)
  end

  defp filtered_posts_query(filter) do
    Post.available(filter)
    |> where([p], p.approved? and not p.private?)
    |> join(:left, [p], e in BillBored.Event, on: e.post_id == p.id, as: :events)
    |> join(:left, [p], o in BillBored.BusinessOffer, on: o.post_id == p.id, as: :offers)
    |> post_type_filter(filter[:types] || [:event, :poll, :regular, :vote])
    |> where([p, events: e, offers: o],
      p.inserted_at > ago(1, "day") or
      e.other_date > ago(12, "hour") or
      o.expires_at > fragment("NOW() at time zone 'utc'")
    )
    |> business_post_filter(filter[:is_business])
    |> where(^dynamic_post_filter(filter))
  end

  def list_markers({%BillBored.Geo.Point{} = location, radius}, filter \\ []) do
    radius_precision = BillBored.Geo.Hash.estimate_precision_at(location, 2 * radius)
    clustering_precision = min(12, BillBored.Geo.Hash.estimate_precision_at(location, radius) + 1)
    clustering_mask = ~~~((1 <<< (60 - 5 * clustering_precision)) - 1)

    radius_hashes = BillBored.Geo.Hash.all_within(location, radius, radius_precision)

    clustering_int_hashes =
      case Access.get(filter, :hashes) do
        hashes when is_list(hashes) ->
          hashes |> Enum.map(&BillBored.Geo.Hash.to_integer(&1, 12))

        _ ->
          BillBored.Geo.Hash.all_within(location, radius, clustering_precision)
          |> Enum.map(&BillBored.Geo.Hash.to_integer(&1, 12))
      end

    dynamic =
      radius_hashes
      |> Enum.map(&BillBored.Geo.Hash.to_integer_range(&1, 12))
      |> Enum.reduce(false, fn
        {r0, r1}, false ->
          dynamic([p], fragment("(? BETWEEN ? AND ?)", p.location_geohash, ^r0, ^r1))

        {r0, r1}, q ->
          dynamic([p], fragment("(? BETWEEN ? AND ?)", p.location_geohash, ^r0, ^r1) or ^q)
      end)

    query =
      filtered_posts_query(filter)
      |> where([p], ^dynamic)
      |> where(
        [p],
        fragment("? & (?)::bigint", p.location_geohash, ^clustering_mask) in ^clustering_int_hashes
      )
      |> select([p], %{
        id: p.id,
        location_geohash: fragment("? & (?)::bigint", p.location_geohash, ^clustering_mask),
        count: count() |> over(:geohash),
        events_count: count() |> over(:posts),
        avg_x: avg(fragment("ST_X(COALESCE(?, ?)::geometry)", p.fake_location, p.location)) |> over(:geohash),
        avg_y: avg(fragment("ST_Y(COALESCE(?, ?)::geometry)", p.fake_location, p.location)) |> over(:geohash),
        row_number: row_number() |> over(:geohash)
      })
      |> windows([p, events: e, offers: o],
        posts: [partition_by: p.id],
        geohash: [
          partition_by: fragment("? & (?)::bigint", p.location_geohash, ^clustering_mask),
          order_by: [
            asc: abs_date_diff_from_now(e.date),
            asc: abs_date_diff_from_now(p.inserted_at),
            asc: abs_date_diff_from_now(o.expires_at)
          ],
          frame: fragment("RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING")
        ]
      )

    posts =
      from(p in Post,
        inner_join: q in subquery(query),
        on: p.id == q.id,
        where: q.row_number <= 3,
        order_by: [asc: q.location_geohash, asc: q.row_number],
        select_merge: %{
          posts_count: q.count - (q.events_count - 1),
          location: fragment("ST_MakePoint(?, ?)", q.avg_x, q.avg_y),
          location_geohash: q.location_geohash
        }
      )
      |> preload([:author, :admin_author])
      |> Repo.all()

    posts
    |> Enum.chunk_while(
      {nil, nil},
      fn
        post, {nil, nil} ->
          marker = %{
            precision: clustering_precision,
            location: post.location,
            location_geohash: Geohash.encode(post.location.lat, post.location.long, 12),
            posts_count: post.posts_count,
            top_posts: [post]
          }

          {:cont, {post.location_geohash, marker}}

        %{location_geohash: geohash} = post, {geohash, %{top_posts: posts} = marker} ->
          {:cont, {geohash, Map.put(marker, :top_posts, [post | posts])}}

        post, {_, %{top_posts: posts} = marker} ->
          new_marker = %{
            precision: clustering_precision,
            location: post.location,
            location_geohash: Geohash.encode(post.location.lat, post.location.long, 12),
            posts_count: post.posts_count,
            top_posts: [post]
          }

          {:cont, Map.put(marker, :top_posts, Enum.reverse(posts)),
           {post.location_geohash, new_marker}}
      end,
      fn
        {nil, nil} ->
          {:cont, []}

        {_, %{top_posts: posts} = marker} ->
          {:cont, Map.put(marker, :top_posts, Enum.reverse(posts)), nil}
      end
    )
  end

  defp order_by_date_proximity(query) do
    order_by(query, [p, events: e, offers: o],
      asc: abs_date_diff_from_now(e.date),
      asc: abs_date_diff_from_now(p.inserted_at),
      asc: abs_date_diff_from_now(o.expires_at)
    )
  end

  defp maybe_include_self_social_counters(query, %{for_id: user_id}) do
    query
    |> join(:left_lateral, [p], u in fragment("SELECT TRUE upvoted FROM posts_upvotes WHERE user_id = ? AND post_id = ?", ^user_id, p.id), as: :self_upvotes)
    |> join(:left_lateral, [p], d in fragment("SELECT TRUE downvoted FROM posts_downvotes WHERE user_id = ? AND post_id = ?", ^user_id, p.id), as: :self_downvotes)
    |> select_merge([self_upvotes: u, self_downvotes: d], %{
      user_upvoted?: coalesce(u.upvoted, false),
      user_downvoted?: coalesce(d.downvoted, false)
    })
  end

  defp maybe_include_self_social_counters(query, _), do: query

  defp with_social_counters(query, filter) do
    query
    |> join(:inner_lateral, [p], u in fragment("SELECT count(*) count FROM posts_upvotes WHERE post_id = ?", p.id), as: :upvotes)
    |> join(:inner_lateral, [p], d in fragment("SELECT count(*) count FROM posts_downvotes WHERE post_id = ?", p.id), as: :downvotes)
    |> join(:inner_lateral, [p], c in fragment("SELECT count(*) count FROM posts_comments WHERE post_id = ?", p.id), as: :comments)
    |> select_merge([upvotes: u, downvotes: d, comments: c], %{
      upvotes_count: u.count,
      downvotes_count: d.count,
      comments_count: c.count
    })
    |> maybe_include_self_social_counters(filter)
  end

  def list_by_geohash_at_location(
        {%BillBored.Geo.Point{} = location, radius},
        precision,
        filter \\ []
      ) do
    clustering_precision = precision
    clustering_mask = ~~~((1 <<< (60 - 5 * clustering_precision)) - 1)
    radius_precision = max(1, precision - 1)

    {:ok, radius_hashes} = BillBored.Geo.Hash.all_within_safe(location, radius, radius_precision)

    {:ok, clustering_hashes} = BillBored.Geo.Hash.all_within_safe(location, radius, clustering_precision)
    clustering_int_hashes = clustering_hashes |> Enum.map(&BillBored.Geo.Hash.to_integer(&1, 12))

    dynamic =
      radius_hashes
      |> Enum.map(&BillBored.Geo.Hash.to_integer_range(&1, 12))
      |> Enum.reduce(false, fn
        {r0, r1}, false ->
          dynamic([p], fragment("(? BETWEEN ? AND ?)", p.location_geohash, ^r0, ^r1))

        {r0, r1}, q ->
          dynamic([p], fragment("(? BETWEEN ? AND ?)", p.location_geohash, ^r0, ^r1) or ^q)
      end)

    page = Access.get(filter, :page, 1)
    page_size = Access.get(filter, :page_size, @default_page_size)
    offset = (page - 1) * page_size

    posts =
      filtered_posts_query(filter)
      |> with_social_counters(filter)
      |> order_by_date_proximity()
      |> where([p], ^dynamic)
      |> where(
        [p],
        fragment("? & (?)::bigint", p.location_geohash, ^clustering_mask) in ^clustering_int_hashes
      )
      |> offset(^offset)
      |> limit(^page_size)
      |> preload([
        :media_files,
        :interests,
        :author,
        :admin_author,
        :business,
        :business_admin,
        :business_offer,
        polls: [items: :media_files],
        place: :types,
        events: [:media_files, :attendees, place: :types]
      ])
      |> Repo.all()

    %{
      entries: posts,
      page_number: page,
      page_size: page_size
    }
  end

  def update_location_geohash(query) do
    Repo.transaction(fn _ ->
      Repo.stream(query)
      |> Stream.chunk_every(1000)
      |> Stream.map(fn chunk ->
        updates =
          Enum.map(chunk, fn p ->
            Map.put(
              Map.take(p, [:id, :type, :author_id, :admin_author_id, :location, :inserted_at, :updated_at]),
              :location_geohash,
              BillBored.Geo.Hash.to_integer(Geohash.encode(p.location.lat, p.location.long, 12))
            )
          end)

        {count, _} =
          Repo.insert_all(Post, updates,
            conflict_target: [:id],
            on_conflict: {:replace, [:location_geohash]}
          )

        count
      end)
      |> Enum.reduce(0, fn n, acc -> acc + n end)
    end)
  end

  defp validate_business_privileges(business_account, filter) do
    {include_unapproved, filter} = Map.pop(Enum.into(filter, %{}), :include_unapproved)
    for_id = filter[:for_id]

    case {include_unapproved, for_id} do
      {true, nil} ->
        {:error, :insufficient_privileges}

      {true, for_id} ->
        case User.Memberships.get_by_member_id(business_account, for_id) do
          %{role: role} when role in ["owner", "admin"] ->
            {:ok, Map.put(filter, :include_unapproved, :all)}

          %{role: role} when role == "member" ->
            {:ok, Map.put(filter, :include_unapproved, {:own, for_id})}

          _ ->
            {:error, :insufficient_privileges}
        end

      _ ->
        {:ok, Map.delete(filter, :include_unapproved)}
    end
  end

  defp unapproved_filter(query, :all), do: query
  defp unapproved_filter(query, {:own, for_id}) do
    join(query, :left, [p], m in User.Membership,
      on: m.business_account_id == p.business_id and
          m.member_id == p.author_id and
          m.member_id == ^for_id,
      as: :author_membership
    )
    |> where([p, author_membership: m], p.approved? or not is_nil(m.member_id))
  end

  defp unapproved_filter(query, nil), do: where(query, [p], p.approved?)

  def list_by_business_account(%User{id: business_id} = business_account, filter) do
    with {:ok, filter} <- validate_business_privileges(business_account, filter) do
      page = Access.get(filter, :page, 1)
      page_size = Access.get(filter, :page_size, @default_page_size)
      offset = (page - 1) * page_size

      posts =
        Post.available(filter)
        |> post_type_filter(filter[:types] || [:event, :poll, :regular, :vote, :offer])
        |> unapproved_filter(filter[:include_unapproved])
        |> where([p], not p.private?)
        |> where([p], p.business_id == ^business_id)
        |> order_by([p], [desc: p.inserted_at])
        |> offset(^offset)
        |> limit(^page_size)
        |> preload([
          :media_files,
          :interests,
          :author,
          :admin_author,
          :business,
          :business_admin,
          :business_offer,
          polls: [items: :media_files],
          place: :types,
          events: [:media_files, :attendees, place: :types]
        ])
        |> Repo.all()

      %{
        entries: posts,
        page_number: page,
        page_size: page_size
      }
    end
  end

  @spec post_type_filter(Ecto.Query.t(), post_types) :: Ecto.Query.t()
  defp post_type_filter(query, post_types) do
    raw_post_types =
      Enum.map(post_types, fn post_type ->
        case post_type do
          :event -> "event"
          :vote -> "vote"
          :regular -> "regular"
          :poll -> "poll"
          :offer -> "offer"
          "event" -> "event"
          "vote" -> "vote"
          "regular" -> "regular"
          "poll" -> "poll"
          "events" -> "event"
          "votes" -> "vote"
          "thoughts" -> "regular"
          "polls" -> "poll"
          "offer" -> "offer"
        end
      end)

    where(query, [p], p.type in ^raw_post_types)
  end

  defp business_post_filter(query, true), do: where(query, [p], not is_nil(p.business_id))
  defp business_post_filter(query, _), do: query

  defp non_empty_value(nil), do: nil
  defp non_empty_value([]), do: nil

  defp non_empty_value(value) when is_binary(value) do
    unless String.trim(value) == "" do
      value
    end
  end

  defp non_empty_value(other), do: other

  defp dynamic_post_filter(filter) do
    conditions = true
    # TODO do all these quesries have corresponding indices?

    conditions =
      if keyword = non_empty_value(filter[:keyword]) do
        pattern = "%#{keyword}%"

        dynamic([events: e], ilike(e.title, ^pattern))
      else
        conditions
      end

    conditions =
      case non_empty_value(filter[:show_free]) do
        nil -> conditions
        true -> dynamic([events: e], e.price == 0.0 and ^conditions)
        false -> dynamic([events: e], e.price > 0.0 and ^conditions)
      end

    # TODO this is most likely unnecessary
    conditions =
      case non_empty_value(filter[:show_paid]) do
        nil -> conditions
        true -> dynamic([events: e], e.price > 0.0 and ^conditions)
        false -> dynamic([events: e], e.price == 0.0 and ^conditions)
      end

    conditions =
      case non_empty_value(filter[:show_child_friendly]) do
        nil ->
          conditions

        friendly? when friendly? in [true, false] ->
          dynamic([events: e], e.child_friendly == ^friendly? and ^conditions)
      end

    conditions =
      case non_empty_value(filter[:show_courses]) do
        true ->
          conditions

        _other ->
          # TODO possibly refactor if this filter stays
          dynamic(
            [p, events: e],
            not ((ilike(p.title, "%devops%") or ilike(p.title, "%certification%") or
                    ilike(p.title, "%lsat%") or ilike(p.title, "%gmat%") or
                    ilike(p.title, "%class%") or ilike(p.title, "%training%") or
                    ilike(p.title, "%course%") or ilike(p.title, "%microsoft%") or
                    ilike(p.title, "%certified%")) and (not is_nil(e.price) and e.price >= 200.00)) and
              ^conditions
          )
      end

    conditions =
      case non_empty_value(filter[:dates]) do
        nil ->
          conditions

        [datetime] ->
          day_start = %{datetime | hour: 0, minute: 0, second: 0}
          day_end = %{datetime | hour: 23, minute: 59, second: 59}

          dynamic(
            [events: e],
            e.date <= ^day_end and
              e.other_date >= ^day_start and
              ^conditions
          )

        [start_datetime, end_datetime] ->
          start_datetime = %{start_datetime | hour: 23, minute: 59, second: 59}
          end_datetime = %{end_datetime | hour: 0, minute: 0, second: 0}

          dynamic(
            [events: e],
            e.date <= ^start_datetime and
              e.other_date >= ^end_datetime and
              ^conditions
          )
      end

    if categories = non_empty_value(filter[:categories]) do
      # TODO this is probably slow
      dynamic(
        [events: e],
        fragment(
          "array_length(?, 1) > 0",
          fragment(
            "select array(select unnest(?) intersect select unnest(?::varchar[]))",
            e.categories,
            ^categories
          )
        )
      )
    else
      conditions
    end
  end

  # TODO dry up
  # TODO: uncomment
  # defmacrop total_votes_count(post_id) do
  #   quote do
  #     fragment(
  #       "select count(i.id) from posts as p, polls_items as i, pst_pollitem_votes as v
  #       where p.id = i.poll_id
  #       and i.id = v.pollitem_id
  #       and p.id = ?",
  #       unquote(post_id)
  #     )
  #   end
  # end

  # defmacrop attendes_count(post_id) do
  #   quote do
  #     fragment(
  #       "SELECT COUNT(*) FROM pst_event_attendees WHERE event_id = ?",
  #       unquote(post_id)
  #     )
  #   end
  # end

  # defmacrop is_user_attending(post_id, user_id) do
  #   quote do
  #     fragment(
  #       "SELECT COUNT(id) FROM pst_event_attendees WHERE event_id = ? and userprofile_id = ?",
  #       unquote(post_id),
  #       unquote(user_id)
  #     )
  #   end
  # end

  defp query(module, [id]) do
    module
    |> where([r], r.post_id == ^id)
  end

  defp query(module, ids) do
    module
    |> where([r], r.post_id in ^ids)
  end

  defp count(module, ids, for_id: user_id) do
    module
    |> query(ids)
    |> where([r], r.user_id == ^user_id)
    |> select([r], count(r.id))
    |> Repo.one()
  end

  defp count(module, ids) do
    module
    |> query(ids)
    |> select([r], count(r.id))
    |> Repo.one()
  end

  defp add_statistics(post_s, for: user) do
    add_statistics(post_s, for_id: user.id)
  end

  defp add_statistics(%{id: id} = post, for_id: user_id) do
    {:ok, stats} =
      Multi.new()
      |> Multi.run(:upvotes_count, fn _repo, _changes ->
        {:ok, count(Upvote, [id])}
      end)
      |> Multi.run(:downvotes_count, fn _repo, _changes ->
        {:ok, count(Downvote, [id])}
      end)
      |> Multi.run(:comments_count, fn _repo, _changes ->
        {:ok, count(Comment, [id])}
      end)
      |> Multi.run(:user_upvoted?, fn _repo, _changes ->
        {:ok, count(Upvote, [id], for_id: user_id) == 1}
      end)
      |> Multi.run(:user_downvoted?, fn _repo, _changes ->
        {:ok, count(Downvote, [id], for_id: user_id) == 1}
      end)
      |> Repo.transaction()

    post = Map.merge(post, stats)

    post =
      case post.events do
        [] ->
          post

        events ->
          events = Enum.map(events, &Events.add_statistics(&1, for_id: user_id))
          %{post | events: events}
      end

    case post.polls do
      [] ->
        post

      polls ->
        polls = Enum.map(polls, &Polls.add_statistics(&1, user_id))
        %{post | polls: polls}
    end
  end

  # WIP:
  # defp add_statistics(post_q, for_id: user_id) do
  #   {:ok, result} =
  #     Multi.new()
  #     |> Multi.run(:posts, fn _changes ->
  #       posts = Repo.all(post_q)
  #       {:ok, {Enum.map(posts, & &1.id), posts}}
  #     end)
  #     |> Multi.run(:upvotes_count, fn %{posts: {ids, _}} ->
  #       {:ok, count(Upvote, ids)}
  #     end)
  #     |> Multi.run(:downvotes_count, fn %{posts: {ids, _}} ->
  #       {:ok, count(Downvote, ids)}
  #     end)
  #     |> Multi.run(:comments_count, fn %{posts: {ids, _}} ->
  #       {:ok, count(Comment, ids)}
  #     end)
  #     |> Multi.run(:user_upvoted?, fn %{posts: {ids, _}} ->
  #       {:ok, count(Upvote, ids, for_id: user_id) == 1}
  #     end)
  #     |> Multi.run(:user_downvoted?, fn %{posts: {ids, _}} ->
  #       {:ok, count(Downvote, ids, for_id: user_id) == 1}
  #     end)
  #     |> Repo.transaction()

  #   {_, posts} = result.posts

  #   for post <- posts do

  #     Map.merge(post, stats)
  #   end
  # end

  defp count_q(module, ids) do
    module
    |> where([d], d.post_id in ^ids)
    |> group_by([d], d.post_id)
    |> select([d], %{post_id: d.post_id, count: count(d.id)})
  end

  defp count_q(module, ids, user_id) do
    module
    |> where([d], d.user_id == ^user_id)
    |> where([d], d.post_id in ^ids)
    |> group_by([d], d.post_id)
    |> select([d], %{post_id: d.post_id, count: count(d.id)})
  end

  defp add_statistics(post_query, ids, user_id) do
    post_query
    |> join(:left, [p], u in subquery(count_q(Upvote, ids)), on: p.id == u.post_id)
    |> join(:left, [p], d in subquery(count_q(Downvote, ids)), on: p.id == d.post_id)
    |> join(:left, [p], c in subquery(count_q(Comment, ids)), on: p.id == c.post_id)
    |> join(:left, [p], uu in subquery(count_q(Upvote, ids, user_id)), on: p.id == uu.post_id)
    |> join(:left, [p], ud in subquery(count_q(Downvote, ids, user_id)), on: p.id == ud.post_id)
    |> select([p, ..., u, d, c, uu, ud], %{
      p
      | downvotes_count: d.count,
        upvotes_count: u.count,
        comments_count: c.count,
        user_upvoted?: uu.count > 0,
        user_downvoted?: ud.count > 0
    })
  end

  defp index_posts(author_id, params) do
    posts =
      Post.available(params)
      |> where([p], p.private? == false)
      |> where([p], p.approved?)
      |> where([p], p.author_id == ^author_id)

    ids =
      posts
      |> select([p], p.id)
      |> Repo.all()

    user_id = params[:for_id] || (params[:for] && params[:for].id)

    posts
    |> add_statistics(ids, user_id || -1)
  end

  def index(author_id, type, params) do
    result =
      author_id
      |> index_posts(params)
      |> where([p], type: ^type)
      |> order_by([p], desc: p.updated_at)
      |> preload([:media_files])
      |> Repo.paginate(params)

    put_in(result.entries, Enum.map(result.entries, &BillBored.Helpers.normalize/1))
  end

  def index(author_id, params) do
    result =
      author_id
      |> index_posts(params)
      |> order_by([p], desc: p.updated_at)
      |> preload([:media_files])
      |> Repo.paginate(params)

    put_in(result.entries, Enum.map(result.entries, &BillBored.Helpers.normalize/1))
  end

  defp query() do
    Post
    |> where([p], not p.private?)
    |> where([p], p.approved?)
  end

  # TODO: decide what to do with friends ids
  defp personal_query(user_id) do
    #    friends_ids = Users.list_friend_ids(user_id)
    followings_id = Users.user_followings_ids(user_id)

    query()
    |> join(:left, [p], pi in PostInterest, on: p.id == pi.post_id)
    |> join(
      :left,
      [p, pi],
      ui in User.Interest,
      on: pi.interest_id == ui.interest_id and ui.user_id == ^user_id
    )
    |> where([p, pi, ui], not is_nil(ui.id) or p.author_id in ^followings_id)
  end

  defp ids_by_location({%BillBored.Geo.Point{} = point, radius}, user_id) do
    user_id
    |> personal_query()
    |> where([p], st_dwithin_in_meters(p.location, ^point, ^radius))
    |> select([p], p.id)
    |> Repo.all()
  end

  defp ids_by_location(%BillBored.Geo.Polygon{} = polygon, user_id) do
    user_id
    |> personal_query()
    |> where([p], st_covered_by(p.location, ^polygon))
    |> select([p], p.id)
    |> Repo.all()
  end

  defp ids_by_location({%BillBored.Geo.Point{} = point, radius}) do
    query()
    |> where([p], st_dwithin_in_meters(p.location, ^point, ^radius))
    |> select([p], p.id)
    |> Repo.all()
  end

  defp ids_by_location(%BillBored.Geo.Polygon{} = polygon) do
    query()
    |> where([p], st_covered_by(p.location, ^polygon))
    |> select([p], p.id)
    |> Repo.all()
  end

  def get_statistics([], _user_id), do: []

  def get_statistics(ids, user_id) do
    Post
    |> where([p], p.id in ^ids)
    |> add_statistics(ids, user_id)
    |> Repo.all()
  end

  defp count_comments(post_id) do
    Post.Comment
    |> where(post_id: ^post_id)
    |> select([c], count(c.id))
    |> Repo.one!()
  end

  defp count_total_expressions(post_id) do
    upvote_count =
      Upvote
      |> group_by([u], u.post_id)
      |> select([u], %{count: count(u.id), post_id: u.post_id})

    downvote_count =
      Downvote
      |> group_by([d], d.post_id)
      |> select([d], %{count: count(d.id), post_id: d.post_id})

    Post
    |> where(id: ^post_id)
    |> join(:left, [p], u in subquery(upvote_count), on: p.id == u.post_id)
    |> join(:left, [p], d in subquery(downvote_count), on: p.id == d.post_id)
    |> select([p, u, d], u.count + d.count)
    |> Repo.one!()
  end

  @spec new_popular_post?(Post.t()) :: boolean
  def new_popular_post?(%Post{popular_notified?: true}) do
    # already notified about its popularity, so not new
    false
  end

  def new_popular_post?(%Post{popular_notified?: false, id: post_id}) do
    cond do
      count_total_expressions(post_id) >= 300 -> true
      count_comments(post_id) >= 250 -> true
      true -> false
    end
  end

  def mark_popular_post_notified(post_id) do
    Post
    |> where(id: ^post_id)
    |> Repo.update_all(set: [popular_notified?: true])

    :ok
  end

  def paginate(params) do
    # page = params[:page] || 1
    # page_size = params[:page_size] || @default_page_size
    sort_field = params[:sort_field] || "updated_at"
    sort_direction = params[:sort_direction] || "desc"
    keyword = params[:keyword] || ""
    filter_type = params[:filter_type] || "event"
    filter_approved = params[:filter_approved] || "all"

    query = Post
      |> order_by([{^String.to_atom(sort_direction), ^String.to_atom(sort_field)}])
      |> preload([:media_files, :events, :polls])

    query = if keyword == "" do
      query
    else
      keyword = "%#{keyword}%"
      query
      |> join(:left, [p], a in assoc(p, :author))
      |> join(:left, [p], a in assoc(p, :admin_author))
      |> where([p, a, aa],
        like(p.title, ^keyword) or
        like(p.body, ^keyword) or
        like(a.username, ^keyword) or
        like(a.first_name, ^keyword) or
        like(a.last_name, ^keyword) or
        like(aa.username, ^keyword) or
        like(aa.first_name, ^keyword) or
        like(aa.last_name, ^keyword)
      )
    end

    query = if filter_type == "all" or filter_type == "" do
      query
    else
      query
      |> where([a], a.type == ^filter_type)
    end

    query = if filter_approved == "all" or filter_approved == "" do
      query
    else
      if filter_approved == "true" do
        query
        |> where([a], a.approved? == true)
      else
        query
        |> where([a], a.approved? == false)
      end
    end

    page = Repo.paginate(query, params)

    %{
      entries: Enum.map(page.entries, &add_statistics(&1, for_id: -1)),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries,
      sort_field: sort_field,
      sort_direction: sort_direction,
      keyword: keyword,
      filter_type: filter_type
    }
  end
end
