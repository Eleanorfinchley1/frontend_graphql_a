defmodule BillBored.Interests do
  import Ecto.Query
  alias BillBored.{Interest, User, Post}

  def get!(id) do
    interest = Repo.get!(Interest, id)
    %{interest | popularity: count_popularity(id)}
  end

  def create(attrs \\ %{}) do
    %Interest{}
    |> Interest.changeset(attrs)
    |> Repo.insert()
  end

  def update(%Interest{} = interest, attrs \\ %{}) do
    interest
    |> Interest.update_changeset(attrs)
    |> Repo.update()
  end

  def delete(id) do
    if interest = Repo.get(Interest, id) do
      Repo.delete(interest)
    end
  end

  # TODO: rewrite
  defp count_popularity(module, id) do
    module
    |> where([ui], ui.interest_id == ^id)
    |> select([ui], count(ui.id))
    |> Repo.one()
  end

  defp count_popularity(id) do
    [User.Interest, Post.Interest, Post.Comment.Interest]
    |> Enum.map(&count_popularity(&1, id))
    |> Enum.sum()
  end

  # TODO: solve known issue.
  # TODO: what issue? (arkadii)
  def index(%{"search" => search} = params) do
    Interest
    |> where([i], ilike(i.hashtag, ^"#{search}%"))
    |> do_index(params)
  end

  def index(params) do
    do_index(Interest, params)
  end

  # TODO use union after upgrading to ecto v3
  defp do_index(queryable, params) do
    query =
      queryable
      |> where(disabled?: false)
      |> join(:left, [i], pi in Post.Interest, on: pi.interest_id == i.id)
      |> join(:left, [i], pci in Post.Comment.Interest, on: pci.interest_id == i.id)
      |> join(:left, [i], ic in assoc(i, :interest_categories))
      |> select_merge([i, pi, pci, ic], %{
        icon: fragment("COALESCE(?, ?)", i.icon, ic.icon),
        posts_count: count(pi.id) |> over(partition_by: i.id),
        comments_count: count(pci.id) |> over(partition_by: i.id),
        category_rn: row_number() |> over(partition_by: i.id, order_by: [asc: fragment("? NULLS LAST", ic.id), asc: fragment("? NULLS LAST", ic.icon)])
      })

    from(q in subquery(query),
      select_merge: %{
        popularity: q.posts_count + q.comments_count,
      },
      order_by: [desc: q.posts_count + q.comments_count, asc: q.hashtag],
      where: q.category_rn == 1
    )
    |> Repo.paginate(params)
  end

  def list() do
    query =
      Interest
      |> where(disabled?: false)
      |> join(:left, [i], pi in Post.Interest, on: pi.interest_id == i.id)
      |> join(:left, [i], pci in Post.Comment.Interest, on: pci.interest_id == i.id)
      |> join(:left, [i], ic in assoc(i, :interest_categories))
      |> select_merge([i, pi, pci, ic], %{
        icon: fragment("COALESCE(?, ?)", i.icon, ic.icon),
        posts_count: count(pi.id) |> over(partition_by: i.id),
        comments_count: count(pci.id) |> over(partition_by: i.id),
        category_rn: row_number() |> over(partition_by: i.id, order_by: [asc: fragment("? NULLS LAST", ic.id), asc: fragment("? NULLS LAST", ic.icon)])
      })

    from(q in subquery(query),
      select_merge: %{
        popularity: q.posts_count + q.comments_count,
      },
      order_by: [desc: q.posts_count + q.comments_count, asc: q.hashtag],
      where: q.category_rn == 1
    )
    |> Repo.all()
  end

  defp check(interests) do
    changesets = Enum.map(interests, &Interest.changeset(%Interest{}, &1))

    for c <- changesets, not c.valid? do
      {msg, [{key, value} | _]} = c.errors[:hashtag]
      msg = String.replace(msg, "%{#{key}}", to_string(value))

      "hashtag \"#{c.changes.hashtag}\" could not be added: #{msg}"
    end
  end

  def insert_and_get_back([]) do
    {:ok, []}
  end

  def insert_and_get_back(interests) do
    interests =
      interests
      |> Enum.map(&Interest.wrap/1)
      |> Enum.reject(&(&1["hashtag"] == ""))

    errors = check(interests)

    if errors == [] do
      tags = Enum.map(interests, &Interest.normalize(&1["hashtag"]))

      interests =
        Enum.map(tags, fn tag ->
          %{
            hashtag: tag,
            inserted_at: DateTime.utc_now()
          }
        end)

      Repo.insert_all(Interest, interests, on_conflict: :nothing)

      {:ok, Repo.all(from(t in Interest, where: fragment("LOWER(?)", t.hashtag) in ^tags))}
    else
      {:error, errors}
    end
  end

  def paginate(params) do
    # page = params[:page] || 1
    # page_size = params[:page_size] || @default_page_size
    # sort_field = params[:sort_field] || "id"
    # sort_direction = params[:sort_direction] || "asc"
    keyword = params[:keyword] || ""
    filter_disabled = params[:filter_disabled] || "all"

    query =
      Interest
      |> join(:left, [i], pi in Post.Interest, on: pi.interest_id == i.id)
      |> join(:left, [i], pci in Post.Comment.Interest, on: pci.interest_id == i.id)
      |> join(:left, [i], ic in assoc(i, :interest_categories))
      |> select_merge([i, pi, pci, ic], %{
        icon: fragment("COALESCE(?, ?)", i.icon, ic.icon),
        posts_count: count(pi.id) |> over(partition_by: i.id),
        comments_count: count(pci.id) |> over(partition_by: i.id),
        category_rn: row_number() |> over(partition_by: i.id, order_by: [asc: fragment("? NULLS LAST", ic.id), asc: fragment("? NULLS LAST", ic.icon)])
      })

    query = if filter_disabled == "all" or filter_disabled == "" do
      query
    else
      if filter_disabled == "true" do
        query
        |> where([a], a.disabled? == true)
      else
        query
        |> where([a], a.disabled? == false)
      end
    end

    query = if keyword == "" do
      query
    else
      keyword = "%#{keyword}%"
      query
      |> where([a], like(a.hashtab, ^keyword))
    end

    page = from(q in subquery(query),
      select_merge: %{
        popularity: q.posts_count + q.comments_count,
      },
      order_by: [desc: q.posts_count + q.comments_count, asc: q.hashtag],
      where: q.category_rn == 1
    )
    |> Repo.paginate(params)

    %{
      entries: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries,
      # sort_field: sort_field,
      # sort_direction: sort_direction,
      keyword: keyword,
      filter_disabled: filter_disabled
    }
  end
end
