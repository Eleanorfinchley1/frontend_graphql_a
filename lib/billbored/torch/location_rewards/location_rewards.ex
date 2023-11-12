defmodule BillBored.Torch.LocationRewards do
  @moduledoc """
  The Torch context.
  """

  import Ecto.Query, warn: false

  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias BillBored.{User, User.Block}
  alias BillBored.Torch.LocationRewardDecorator
  alias BillBored.LocationReward
  alias BillBored.LocationRewards.Notification

  @pagination [page_size: 15]
  @pagination_distance 5

  def create(%LocationRewardDecorator{} = decorator) do
    LocationReward.changeset(%LocationReward{}, %{
      "location" => %BillBored.Geo.Point{long: decorator.longitude, lat: decorator.latitude},
      "radius" => decorator.radius,
      "stream_points" => decorator.stream_points * 10,
      "started_at" => decorator.started_at,
      "ended_at" => decorator.ended_at
    })
    |> Repo.insert()
  end

  def get!(id) do
    Repo.get!(LocationReward, id)
  end

  def delete(%LocationReward{} = location_reward) do
    Repo.delete(location_reward)
  end

  def paginate_location_rewards(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "updated_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <-
           Filtrex.parse_params(
             filter_config(:location_rewards),
             params["location_reward"] || %{}
           ),
         %Scrivener.Page{} = page <- do_paginate_location_rewards(filter, params) do
      {:ok,
       %{
         location_rewards: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
      error -> {:error, error}
    end
  end

  defp do_paginate_location_rewards(filter, params) do
    LocationReward
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  defp filter_config(:location_rewards) do
    defconfig do
      number(:id)
      number(:radius)
      number(:stream_points)
      datetime(:started_at)
      datetime(:ended_at)
      datetime(:inserted_at)
      datetime(:updated_at)
    end
  end

  def notify_to_filtered_users(params) do
    case filter_all_users(params) do
      {:ok, users} ->
        try do
          {:ok, users
            |> Enum.map(fn user ->
              %{
                user_id: user.id,
                location_reward_id: String.to_integer(params["location_reward_id"]),
                inserted_at: DateTime.utc_now()
              }
            end)
            |> Enum.chunk_every(10_000)
            |> Enum.reduce(0, fn chunk, total_count ->
              {count, _} = Repo.insert_all(Notification, chunk)
              total_count + count
            end)
          }
        rescue
          error -> {:error, error}
        end
      {:error, error} ->
        {:error, error}
    end
  end

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

  def filter_all_users(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "date_joined")

    {:ok, _sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, _sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter_params, custom_filters} <- extract_custom_filters(params["user"] || %{}),
         {:ok, filter} <- Filtrex.parse_params(filter_config(:users), filter_params),
         users <- do_filter_all_users(filter, params, custom_filters) do
      {:ok, users}
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
      |> apply_custom_user_filters(custom_filters)

    queryable
    |> join(:left, [u], n in Notification, on: u.id == n.user_id and n.location_reward_id == ^String.to_integer(params["location_reward_id"]), as: :notification)
    |> select_merge([notification: n], %{location_reward_notification_id: n.id})
    |> where([notification: n], is_nil(n.id))
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  defp do_filter_all_users(filter, params, custom_filters) do
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
      |> apply_custom_user_filters(custom_filters)

    queryable
    |> join(:left, [u], n in Notification, on: u.id == n.user_id and n.location_reward_id == ^String.to_integer(params["location_reward_id"]), as: :notification)
    |> select_merge([notification: n], %{location_reward_notification_id: n.id})
    |> where([notification: n], is_nil(n.id))
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> Repo.all()
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

  defp apply_custom_user_filters(queryable, []), do: queryable

  defp apply_custom_user_filters(queryable, [{:access_equals, value} | rest]) do
    where(queryable, [u], fragment("?->>'access' = ?", u.flags, ^value))
    |> apply_custom_user_filters(rest)
  end

  defp apply_custom_user_filters(queryable, [{:event_provider_equals, "none"} | rest]) do
    where(queryable, [u], is_nil(u.event_provider))
    |> apply_custom_user_filters(rest)
  end

  defp apply_custom_user_filters(queryable, [{:event_provider_equals, value} | rest]) do
    where(queryable, [u], u.event_provider == ^value)
    |> apply_custom_user_filters(rest)
  end

  defp apply_custom_user_filters(queryable, _), do: queryable
end
