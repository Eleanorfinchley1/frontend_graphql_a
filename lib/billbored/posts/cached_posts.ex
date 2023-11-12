defmodule BillBored.CachedPosts do
  import Ecto.Query
  import BillBored.ServiceRegistry, only: [service: 1]

  @config Application.fetch_env!(:billbored, __MODULE__)
  @marker_cache_ttl to_string(@config[:marker_cache_ttl])
  @empty_marker_cache_ttl to_string(@config[:empty_marker_cache_ttl])
  @nil_term :erlang.term_to_binary(nil)
  @lock_ttl 3600

  def list_markers({%BillBored.Geo.Point{} = location, radius}, filter \\ %{}) do
    filter = Enum.into(filter, %{})

    clustering_precision = min(12, BillBored.Geo.Hash.estimate_precision_at(location, radius) + 1)
    clustering_hashes = BillBored.Geo.Hash.all_within(location, radius, clustering_precision)

    {use_cache, cache_suffix} =
      case cache_params(filter) do
        {:error, :not_cacheable} ->
          {false, nil}

        {:ok, ""} ->
          {true, ""}

        {:ok, params} ->
          {true, ":#{params}"}
      end

    {markers_from_cache, missing_hashes} =
      if use_cache do
        get_cached_markers(cache_suffix, clustering_hashes)
      else
        {[], MapSet.new(clustering_hashes)}
      end

    db_markers =
      if MapSet.size(missing_hashes) > 0 do
        filter = Map.put(filter, :hashes, MapSet.to_list(missing_hashes))
        db_markers = BillBored.Posts.list_markers({location, radius}, filter)

        empty_hashes =
          Enum.reduce(db_markers, missing_hashes, fn %{location_geohash: hash}, hashes ->
            MapSet.delete(hashes, binary_part(hash, 0, clustering_precision))
          end)

        if use_cache do
          put_markers_cache(cache_suffix, db_markers, clustering_precision)
          put_empty_markers_cache(cache_suffix, MapSet.to_list(empty_hashes))
        end

        db_markers
      else
        []
      end

    Enum.reject(markers_from_cache ++ db_markers, &is_nil(&1))
  end

  defp get_cached_markers(suffix, hashes) do
    commands = Enum.map(hashes, &["GET", "marker:#{&1}#{suffix}"])

    with {:ok, results} <- service(BillBored.Redix).pipeline(commands) do
      Enum.zip(hashes, results)
      |> Enum.reduce({[], MapSet.new()}, fn
        {hash, %Redix.Error{}}, {markers_from_cache, missing_hashes} ->
          {markers_from_cache, MapSet.put(missing_hashes, hash)}

        {hash, nil}, {markers_from_cache, missing_hashes} ->
          {markers_from_cache, MapSet.put(missing_hashes, hash)}

        {_hash, cached_marker}, {markers_from_cache, missing_hashes} ->
          {[:erlang.binary_to_term(cached_marker) | markers_from_cache], missing_hashes}
      end)
    else
      _ ->
        {[], hashes}
    end
  end

  defp put_markers_cache(_suffix, [], _), do: :ok

  defp put_markers_cache(suffix, markers, precision) do
    commands =
      Enum.map(markers, fn %{location_geohash: geohash} = marker ->
        hash = binary_part(geohash, 0, precision)
        ["SETEX", "marker:#{hash}#{suffix}", @marker_cache_ttl, :erlang.term_to_binary(marker)]
      end)

    with {:ok, _} <- service(BillBored.Redix).pipeline(commands) do
      :ok
    end
  end

  defp put_empty_markers_cache(_suffix, []), do: :ok

  defp put_empty_markers_cache(suffix, hashes) do
    commands =
      Enum.map(hashes, fn hash ->
        ["SETEX", "marker:#{hash}#{suffix}", @empty_marker_cache_ttl, @nil_term]
      end)

    with {:ok, _} <- service(BillBored.Redix).pipeline(commands) do
      :ok
    end
  end

  def cache_params(filter) when map_size(filter) == 0, do: {:ok, ""}

  def cache_params(filter) do
    with true <- is_cacheable?(filter),
         flags <- extract_flags(filter),
         types <- extract_types(filter) do
      params =
        [
          maybe_params(types, "types"),
          maybe_params(flags, "flags")
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join("&")

      {:ok, params}
    else
      _ ->
        {:error, :not_cacheable}
    end
  end

  defp is_cacheable?(%{dates: _}), do: false
  defp is_cacheable?(%{categories: _}), do: false
  defp is_cacheable?(%{keyword: _}), do: false
  defp is_cacheable?(_), do: true

  defp maybe_params([], _name), do: nil
  defp maybe_params(params, name), do: "#{name}=#{Enum.join(params, ",")}"

  defp extract_flags(filter) do
    [
      {:show_courses, false, "courses"},
      {:show_child_friendly, true, "safe"},
      {:show_free, true, "free"},
      {:show_paid, true, "paid"},
      {:is_business, false, "business"}
    ]
    |> Enum.reduce([], fn {flag, include_false, cache_name}, flags ->
      case {Map.get(filter, flag), include_false} do
        {true, _} -> [cache_name | flags]
        {false, true} -> ["no#{cache_name}" | flags]
        _ -> flags
      end
    end)
  end

  defp extract_types(%{types: filter_types}) do
    types =
      [:vote, :poll, :event, :regular]
      |> Enum.reduce([], fn type, types ->
        cond do
          type in filter_types -> [type | types]
          to_string(type) in filter_types -> [type | types]
          true -> types
        end
      end)

    if Enum.count(types) == 4 do
      []
    else
      types
    end
  end

  defp extract_types(_), do: []

  # TODO: Execute inside CachedPosts.Server
  def invalidate_post(%BillBored.Post{location_geohash: inthash}) do
    geohash = BillBored.Geo.Hash.int_to_geobase32(inthash)

    hashes_set =
      Enum.reduce(subhashes(geohash), MapSet.new(), fn hash, hashes_set ->
        MapSet.put(hashes_set, hash)
      end)

    with {:ok, deleted_exact_keys, deleted_matched_keys} <- delete_keys(hashes_set) do
      {:ok, %{deleted_keys: deleted_exact_keys + deleted_matched_keys}}
    end
  end

  def invalidate_stale(since \\ nil) do
    service(BillBored.Redix).with_lock("invalidate_stale:lock", @lock_ttl, fn ->
      with {:ok, since} <- get_last_updated_at(since),
           {:ok, {updated_count, max_updated_at, hashes_set}} <- get_updated_geohashes(since),
           {:ok, deleted_exact_keys, deleted_matched_keys} <- delete_keys(hashes_set) do
        save_last_updated_at(max_updated_at)

        {:ok,
         %{
           updated_locations: updated_count,
           updated_geohashes: MapSet.size(hashes_set),
           deleted_keys: deleted_exact_keys + deleted_matched_keys
         }}
      end
    end)
  end

  def get_last_updated_at(since) when not is_nil(since), do: {:ok, since}

  def get_last_updated_at(nil) do
    case service(BillBored.Redix).command(["GET", "invalidate_stale:last_updated_at"]) do
      {:ok, last_updated_at} when is_binary(last_updated_at) ->
        DateTime.from_unix(String.to_integer(last_updated_at), :microsecond)

      _ ->
        DateTime.from_unix(0)
    end
  end

  def save_last_updated_at(updated_at) do
    timestamp = DateTime.to_unix(updated_at, :microsecond)

    service(BillBored.Redix).command([
      "SET",
      "invalidate_stale:last_updated_at",
      to_string(timestamp)
    ])
  end

  defp subhashes(hash) do
    subhashes(hash |> String.graphemes(), [])
  end

  defp subhashes([], acc), do: acc
  defp subhashes([letter | rest], []), do: subhashes(rest, [letter])

  defp subhashes([letter | rest], [last_hash | _rest] = acc) do
    hash = List.to_string([last_hash, letter])
    subhashes(rest, [hash | acc])
  end

  defp get_updated_geohashes(since) do
    query =
      from(p in BillBored.Post, where: p.updated_at > ^since and p.inserted_at > ago(1, "day"))

    Repo.transaction(fn _ ->
      max_updated_at =
        from(p in query, select: max(p.updated_at))
        |> Repo.one()

      max_updated_at =
        if max_updated_at do
          DateTime.from_naive!(max_updated_at, "Etc/UTC")
        else
          since
        end

      from(p in query, distinct: p.location_geohash, select: p.location_geohash)
      |> Repo.stream()
      |> Stream.chunk_every(1000)
      |> Enum.reduce({0, max_updated_at, MapSet.new()}, fn chunk,
                                                           {updated_count, max_updated_at,
                                                            hashes_set} ->
        hashes_set =
          Enum.reduce(chunk, hashes_set, fn inthash, hashes_set ->
            geohash = BillBored.Geo.Hash.int_to_geobase32(inthash)

            Enum.reduce(subhashes(geohash), hashes_set, fn hash, hashes_set ->
              MapSet.put(hashes_set, hash)
            end)
          end)

        {updated_count + Enum.count(chunk), max_updated_at, hashes_set}
      end)
    end)
  end

  defp delete_keys(hashes_set) do
    deleted_exact_keys =
      Enum.chunk_every(hashes_set, 1000)
      |> Enum.reduce(0, fn hashes, deleted_keys ->
        command = ["DEL" | Enum.map(hashes, &"marker:#{&1}")]
        {:ok, result} = service(BillBored.Redix).command(command)
        deleted_keys + result
      end)

    deleted_matched_keys =
      Enum.reduce(hashes_set, 0, fn hash, deleted_keys ->
        service(BillBored.Redix).stream_keys("marker:#{hash}:*")
        |> Stream.chunk_every(1000)
        |> Enum.reduce(deleted_keys, fn keys, deleted_keys ->
          commands = Enum.map(keys, &["DEL", &1])
          service(BillBored.Redix).pipeline(commands)
          deleted_keys + Enum.count(keys)
        end)
      end)

    {:ok, deleted_exact_keys, deleted_matched_keys}
  end
end
