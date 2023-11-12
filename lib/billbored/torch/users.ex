defmodule BillBored.Torch.Users do
  @moduledoc """
  The Torch context.
  """

  import Ecto.Query, warn: false

  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.{User, User.Block}
  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStream.SpeakerReaction

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of users using filtrex
  filters.

  ## Examples

      iex> list_users(%{})
      %{users: [%User{}], ...}
  """
  @spec paginate_users(map) :: {:ok, map} | {:error, any}
  def paginate_users(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "date_joined")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter_params, custom_filters} <- extract_custom_filters(params["user"] || %{}),
         {:ok, filter} <- Filtrex.parse_params(filter_config(:users), filter_params),
         %Scrivener.Page{} = page <- do_paginate_users(filter, params, custom_filters) do
      {:ok,
        %{
          users: page.entries,
          page_number: page.page_number,
          page_size: page.page_size,
          total_pages: page.total_pages,
          total_entries: page.total_entries,
          distance: @pagination_distance,
          sort_field: sort_field,
          sort_direction: sort_direction
        }
      }
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  def block_params?(%{"user" => %{"blocks_count_greater_than" => _}}), do: true
  def block_params?(%{"user" => %{"blocks_count_greater_than_or" => _}}), do: true
  def block_params?(%{"user" => %{"blocks_count_less_than" => _}}), do: true
  def block_params?(%{"user" => %{"blocked_from_id_equals" => _}}), do: true
  def block_params?(%{"user" => %{"blocked_to_id_equals" => _}}), do: true
  def block_params?(_), do: false

  defp with_blocks(queryable) do
    from(q in queryable,
      distinct: true,
      left_join: bl_from in Block,
      on: bl_from.from_userprofile_id == q.id,
      select_merge: %{
        blocks_count: count(bl_from.id) |> over(partition_by: q.id)
      }
    )
  end

  defp maybe_join_blocked_from(query, %{"user" => %{"blocked_from_id_equals" => blocked_from_id}}) do
    query
    |> join(:inner, [q], b in Block, on: b.to_userprofile_id == q.id and b.from_userprofile_id == ^blocked_from_id, as: :blocked_from)
    |> select_merge([blocked_from: b], %{blocked_from_id: b.from_userprofile_id})
  end
  defp maybe_join_blocked_from(query, _), do: query

  defp maybe_join_blocked_to(query, %{"user" => %{"blocked_to_id_equals" => blocked_to_id}}) do
    query
    |> join(:inner, [q], b in Block, on: b.from_userprofile_id == q.id and b.to_userprofile_id == ^blocked_to_id, as: :blocked_to)
    |> select_merge([blocked_to: b], %{blocked_to_id: b.to_userprofile_id})
  end
  defp maybe_join_blocked_to(query, _), do: query

  defp do_paginate_users(filter, params, custom_filters) do
    queryable =
      if block_params?(params) do
        query =
          with_blocks(User)
          |> where([u], u.is_business == false)
          |> maybe_join_blocked_from(params)
          |> maybe_join_blocked_to(params)
        from(q in subquery(query))
      else
        User
        |> where([u], u.is_business == false)
      end
      |> apply_custom_filters(custom_filters)

    queryable
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @custom_filters ~w[access_equals event_provider_equals]

  def custom_filters(params) do
    {:ok, _, custom_filters} = extract_custom_filters(params["user"] || %{})
    Enum.into(custom_filters, %{})
  end

  defp extract_custom_filters(params) do
    {filter_params, custom_filters} =
      Enum.reduce(params, {%{}, []}, fn {k, v}, {filter_params, custom_filters} ->
        if k in @custom_filters do
          {filter_params, [{String.to_atom(k), v} | custom_filters]}
        else
          {Map.put(filter_params, k, v), custom_filters}
        end
      end)

    {:ok, filter_params, custom_filters}
  end

  defp apply_custom_filters(queryable, []), do: queryable

  defp apply_custom_filters(queryable, [{:access_equals, value} | rest]) do
    where(queryable, [u], fragment("?->>'access' = ?", u.flags, ^value))
    |> apply_custom_filters(rest)
  end

  defp apply_custom_filters(queryable, [{:event_provider_equals, "none"} | rest]) do
    where(queryable, [u], is_nil(u.event_provider))
    |> apply_custom_filters(rest)
  end

  defp apply_custom_filters(queryable, [{:event_provider_equals, value} | rest]) do
    where(queryable, [u], u.event_provider == ^value)
    |> apply_custom_filters(rest)
  end

  defp apply_custom_filters(queryable, _), do: queryable

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  def list_users_with_activities(params) do
    query = User
    |> where([u], is_nil(u.event_provider))
    |> join(:left, [u], ds in DropchatStream, on: u.id == ds.admin_id)
    |> join(:left, [u, _ds], dsr in SpeakerReaction, on: u.id == dsr.speaker_id)
    |> group_by([u], u.id)
    |> select_merge([u, ds, dsr], %{
      streams_count: fragment("COUNT(DISTINCT ?)", ds.id),
      claps_count: fragment("COUNT(DISTINCT ?)", dsr.id)
    })
    |> preload([:points, :university])

    query = if params["joined_from_date"] do
      {:ok, st_date, 0} = DateTime.from_iso8601(params["joined_from_date"] <> "T00:00:00Z")
      query |> where([u], u.date_joined >= ^st_date)
    else
      query
    end

    query = if params["joined_to_date"] do
      {:ok, ed_date, 0} = DateTime.from_iso8601(params["joined_to_date"] <> "T23:59:59Z")
      query |> where([u], u.date_joined <= ^ed_date)
    else
      query
    end

    query
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    Repo.get!(User, id) |> Repo.preload(:recommendations)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.update_changeset(user, %{})
  end

  defp filter_config(:users) do
    defconfig do
      number(:id)
      text(:username)
      text(:first_name)
      text(:last_name)
      text(:email)
      number(:blocked_from_id)
      number(:blocked_to_id)
      number(:blocks_count)
      text(:access)
    end
  end
end
