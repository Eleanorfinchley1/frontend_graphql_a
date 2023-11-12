defmodule BillBored.CachedPostsTest do
  use BillBored.DataCase, async: true

  alias BillBored.CachedPosts
  import Ecto.Query

  @empty_fixture Path.absname("../fixtures/cached_posts/empty.bin", __DIR__)
  @full_fixture Path.absname("../fixtures/cached_posts/full.bin", __DIR__)
  @filter_fixture Path.absname("../fixtures/cached_posts/filter.bin", __DIR__)

  describe "list_markers/2" do
    setup [:start_redix, :create_posts]

    test "caches markers to redis", %{location: location, radius: radius, redix_pid: redix_pid} do
      assert [
        %{
          location_geohash: "dnk7hgnsj5pt",
          posts_count: 2,
          precision: 2
        },
        %{
          location_geohash: "dr5regy3zfrc",
          posts_count: 1,
          precision: 2
        },
        %{
          location_geohash: "f25y26qsr2wc",
          posts_count: 2,
          precision: 2
        },
      ] = CachedPosts.list_markers({location, radius}, [redix_pid: redix_pid])

      {:ok, cached_markers} = BillBored.Stubs.Redix.pipeline([
        ["GET", "marker:dn"],
        ["GET", "marker:dr"],
        ["GET", "marker:f2"],
      ])

      assert [
        %{
          location_geohash: "dnk7hgnsj5pt",
          posts_count: 2,
          precision: 2
        },
        %{
          location_geohash: "dr5regy3zfrc",
          posts_count: 1,
          precision: 2
        },
        %{
          location_geohash: "f25y26qsr2wc",
          posts_count: 2,
          precision: 2
        },
      ] = Enum.map(cached_markers, &(:erlang.binary_to_term(&1)))

      [
        "marker:f0",
        "marker:f8",
        "marker:dp",
        "marker:dx",
        "marker:dq",
        "marker:dw"
      ]
      |> Enum.each(fn key ->
        {:ok, value} = BillBored.Stubs.Redix.command(["GET", key])
        assert nil == :erlang.binary_to_term(value)
      end)
    end

    test "returns correct markers with filter by type", %{location: location, radius: radius, redix_pid: redix_pid} do
      load_redix_fixture(@full_fixture)

      assert [
        %{
          location_geohash: "f2m673zjkcpr",
          posts_count: 1,
          precision: 2,
          top_posts: [
            %{title: "Quebec"}
          ]
        },
      ] = CachedPosts.list_markers({location, radius}, [types: [:vote], redix_pid: redix_pid])
    end

    test "filter by type does not overwrite default caches", %{location: location, radius: radius, redix_pid: redix_pid} do
      load_redix_fixture(@full_fixture)
      CachedPosts.list_markers({location, radius}, [types: [:vote], redix_pid: redix_pid])

      {:ok, cached_markers} = BillBored.Stubs.Redix.pipeline([
        ["GET", "marker:dn"],
        ["GET", "marker:dr"],
        ["GET", "marker:f2"],
      ])

      assert [
        %{
          location_geohash: "dnk7hgnsj5pt",
          posts_count: 2,
          precision: 2
        },
        %{
          location_geohash: "dr5regy3zfrc",
          posts_count: 1,
          precision: 2
        },
        %{
          location_geohash: "f25y26qsr2wc",
          posts_count: 2,
          precision: 2
        },
      ] = Enum.map(cached_markers, &(:erlang.binary_to_term(&1)))

      [
        "marker:f0",
        "marker:f8",
        "marker:dp",
        "marker:dx",
        "marker:dq",
        "marker:dw"
      ]
      |> Enum.each(fn key ->
        {:ok, value} = BillBored.Stubs.Redix.command(["GET", key])
        assert nil == :erlang.binary_to_term(value)
      end)
    end

    test "writes correct cache keys for filter", %{location: location, radius: radius, redix_pid: redix_pid} do
      CachedPosts.list_markers({location, radius}, [types: [:vote, "event"], show_paid: false, redix_pid: redix_pid])

      {:ok, cached_markers} = BillBored.Stubs.Redix.pipeline([["GET", "marker:dn:types=event,vote&flags=nopaid"]])

      assert [
        %{
          location_geohash: "dnq82kgudmrd",
          posts_count: 1,
          precision: 2,
          top_posts: [
            %{title: "Charlotte"}
          ]
        },
      ] = Enum.map(cached_markers, &(:erlang.binary_to_term(&1)))

      ["f0", "f2", "f8", "dp", "dr", "dx", "dq", "dw"]
      |> Enum.each(fn hash ->
        {:ok, value} = BillBored.Stubs.Redix.command(["GET", "marker:#{hash}:types=event,vote&flags=nopaid"])
        assert nil == :erlang.binary_to_term(value)
      end)
    end
  end

  describe "list_markers/2 cache only" do
    setup [:start_redix]

    test "returns empty array when all cached geohashes are marked empty", %{redix_pid: redix_pid} do
      load_redix_fixture(@empty_fixture)

      location = %BillBored.Geo.Point{lat: 40.7142715, long: -74.0059662}
      radius = 700_000

      assert [] == CachedPosts.list_markers({location, radius}, [redix_pid: redix_pid])
    end

    test "returns markers from cache", %{redix_pid: redix_pid} do
      load_redix_fixture(@full_fixture)

      location = %BillBored.Geo.Point{lat: 40.7142715, long: -74.0059662}
      radius = 700_000

      assert [
        %{
          location_geohash: "dnk7hgnsj5pt",
          posts_count: 2,
          precision: 2
        },
        %{
          location_geohash: "dr5regy3zfrc",
          posts_count: 1,
          precision: 2
        },
        %{
          location_geohash: "f25y26qsr2wc",
          posts_count: 2,
          precision: 2
        },
      ] = CachedPosts.list_markers({location, radius}, [redix_pid: redix_pid])
    end

    test "returns filtered markers from cache", %{redix_pid: redix_pid} do
      load_redix_fixture(@filter_fixture)

      location = %BillBored.Geo.Point{lat: 40.7142715, long: -74.0059662}
      radius = 700_000

      assert [
        %{
          location_geohash: "dnq82kgudmrd",
          posts_count: 1,
          precision: 2,
          top_posts: [
            %{title: "Charlotte"}
          ]
        },
      ] = CachedPosts.list_markers({location, radius}, [types: [:vote, "event"], show_paid: false, redix_pid: redix_pid])
    end
  end

  describe "cache_params/1" do
    test "returns error when filter can't be cached" do
      assert {:error, :not_cacheable} = CachedPosts.cache_params(%{keyword: "games"})
      assert {:error, :not_cacheable} = CachedPosts.cache_params(%{dates: [~U[2020-02-02 20:20:20Z]]})
      assert {:error, :not_cacheable} = CachedPosts.cache_params(%{categories: ["books", "yoga"]})
      assert {:error, :not_cacheable} = CachedPosts.cache_params(%{types: [:vote, "regular"], show_free: false, keyword: "test"})
    end

    test "returns correct params" do
      assert {:ok, ""} = CachedPosts.cache_params(%{show_courses: false, for_id: 123})
      assert {:ok, "flags=courses"} = CachedPosts.cache_params(%{show_courses: true})
      assert {:ok, "flags=nopaid,courses"} = CachedPosts.cache_params(%{show_paid: false, show_courses: true})
      assert {:ok, "flags=nopaid,free,courses"} = CachedPosts.cache_params(%{show_free: true, show_paid: false, show_courses: true})
      assert {:ok, "flags=nopaid,free,safe,courses"} = CachedPosts.cache_params(%{show_child_friendly: true, show_free: true, show_paid: false, show_courses: true})
      assert {:ok, "flags=nopaid,free,nosafe,courses"} = CachedPosts.cache_params(%{show_child_friendly: false, show_free: true, show_paid: false, show_courses: true})
      assert {:ok, "flags=business,nopaid,free,nosafe,courses"} = CachedPosts.cache_params(%{show_child_friendly: false, show_free: true, show_paid: false, show_courses: true, is_business: true})
      assert {:ok, "flags=nopaid,free,nosafe,courses"} = CachedPosts.cache_params(%{show_child_friendly: false, show_free: true, show_paid: false, show_courses: true, is_business: false})
      assert {:ok, "flags=business,free"} = CachedPosts.cache_params(%{show_free: true, is_business: true})
      assert {:ok, "types=vote"} = CachedPosts.cache_params(%{types: [:vote]})
      assert {:ok, "types=regular,vote"} = CachedPosts.cache_params(%{types: [:vote, "regular"]})
      assert {:ok, "types=regular,vote"} = CachedPosts.cache_params(%{types: [:regular, :vote, "regular"]})
      assert {:ok, "types=event,poll,vote"} = CachedPosts.cache_params(%{types: ["event", "vote", :poll]})
      assert {:ok, "types=regular,poll,vote"} = CachedPosts.cache_params(%{types: ["poll", "vote", :regular]})
      assert {:ok, ""} = CachedPosts.cache_params(%{types: [:event, "poll", "vote", :regular]})
      assert {:ok, ""} = CachedPosts.cache_params(%{types: ["regular", :poll, "event", :vote]})
      assert {:ok, "types=regular,poll,vote&flags=nopaid,courses"} = CachedPosts.cache_params(%{show_paid: false, show_courses: true, types: ["poll", "vote", :regular]})
      assert {:ok, "flags=nofree"} = CachedPosts.cache_params(%{types: ["regular", :poll, "event", :vote], show_free: false, show_courses: false})
    end
  end

  describe "invalidate_post/1" do
    setup [:start_redix, :insert_keys, :create_posts]

    test "deletes keys according to the post's location_geohash", %{posts: [_p1, _p2, p3, _p4, _p5]} do
      commands =
        [
          "dnq82kgudmrd:flags=nofree",
          "dnq82kgu",
          "dnq8:types=regular,event&flags=safe",
          "dnq",
        ]
        |> Enum.map(&(["SET", "marker:#{&1}", ""]))

      {:ok, _} = BillBored.Stubs.Redix.pipeline(commands)

      assert {:ok, %{deleted_keys: 5}} = BillBored.CachedPosts.invalidate_post(p3)

      assert {:ok, keys} = BillBored.Stubs.Redix.command(["KEYS", "*"])
      assert [
        "marker:dr",
        "marker:dr:types=event",
        "marker:f2",
        "marker:f2vv",
        "marker:f2vv:flags=nopaid",
        "marker:zz"
      ] == Enum.sort(keys)
    end
  end

  describe "invalidate_stale/1" do
    setup [:start_redix, :insert_keys, :create_posts]

    test "deletes correct cache keys" do
      assert {:ok, %{
        updated_locations: 5,
        updated_geohashes: 55,
        deleted_keys: 4
      }} = BillBored.CachedPosts.invalidate_stale()

      assert {:ok, keys} = BillBored.Stubs.Redix.command(["KEYS", "*"])
      assert [
        "invalidate_stale:last_updated_at",
        "marker:f2vv",
        "marker:f2vv:flags=nopaid",
        "marker:zz"
      ] == Enum.sort(keys)

      assert {:ok, saved_updated_at} = BillBored.Stubs.Redix.command(["GET", "invalidate_stale:last_updated_at"])
    end

    test "deletes correct cache keys when only one post was updated since specified datetime", %{posts: [%{id: p1_id} | _rest]} do
      from(p in BillBored.Post, where: p.id == ^p1_id)
      |> Repo.update_all(set: [updated_at: ~U[2035-05-01 00:00:00Z]])

      assert {:ok, %{
        updated_locations: 1,
        updated_geohashes: 12,
        deleted_keys: 2
      }} = BillBored.CachedPosts.invalidate_stale(~U[2035-01-01 00:00:00Z])

      assert {:ok, keys} = BillBored.Stubs.Redix.command(["KEYS", "*"])
      assert [
        "invalidate_stale:last_updated_at",
        "marker:dn",
        "marker:f2",
        "marker:f2vv",
        "marker:f2vv:flags=nopaid",
        "marker:zz"
      ] == Enum.sort(keys)

      assert {:ok, "2061590400000000"} = BillBored.Stubs.Redix.command(["GET", "invalidate_stale:last_updated_at"])
    end

    test "does not delete keys when no post was updated since specified datetime" do
      now = DateTime.to_unix(DateTime.utc_now(), :microsecond)
      {:ok, _} = BillBored.Stubs.Redix.command(["SET", "invalidate_stale:last_updated_at", "#{now}"])

      assert {:ok, %{
        updated_locations: 0,
        updated_geohashes: 0,
        deleted_keys: 0
      }} = BillBored.CachedPosts.invalidate_stale()

      assert {:ok, keys} = BillBored.Stubs.Redix.command(["KEYS", "*"])
      assert [
        "invalidate_stale:last_updated_at",
        "marker:dn",
        "marker:dr",
        "marker:dr:types=event",
        "marker:f2",
        "marker:f2vv",
        "marker:f2vv:flags=nopaid",
        "marker:zz"
      ] == Enum.sort(keys)

      assert {:ok, "#{now}"} == BillBored.Stubs.Redix.command(["GET", "invalidate_stale:last_updated_at"])
    end
  end

  describe "fixtures" do
    setup [:create_posts]

    @tag fixture: true
    test "rebuild empty fixture" do
      start_redix()

      keys = ["f0", "f2", "f8", "dp", "dr", "dx", "dn", "dq", "dw"]

      commands = Enum.map(keys, &(["SET", "marker:#{&1}", :erlang.term_to_binary(nil)]))
      {:ok, _} = BillBored.Stubs.Redix.pipeline(commands)

      store_redix_fixture(keys, @empty_fixture)
    end

    @tag fixture: true
    test "rebuild full fixture", %{location: location, radius: radius} do
      start_redix()

      markers = BillBored.Posts.list_markers({location, radius})

      for %{location_geohash: geohash} = marker <- markers do
        key = "marker:#{binary_part(geohash, 0, 2)}"
        BillBored.Stubs.Redix.command(["SET", key, :erlang.term_to_binary(marker)])
      end

      commands =
        ["f0", "f8", "dp", "dx", "dq", "dw"]
        |> Enum.map(&(["SET", "marker:#{&1}", :erlang.term_to_binary(nil)]))

      {:ok, _} = BillBored.Stubs.Redix.pipeline(commands)

      {:ok, all_keys} = BillBored.Stubs.Redix.command(["KEYS", "*"])
      store_redix_fixture(all_keys, @full_fixture)
    end

    @tag fixture: true
    test "rebuild filter fixture", %{location: location, radius: radius} do
      start_redix()

      markers = BillBored.Posts.list_markers({location, radius}, [types: [:vote, "event"], show_paid: false])

      suffix = ":types=event,vote&flags=nopaid"

      for %{location_geohash: geohash} = marker <- markers do
        key = "marker:#{binary_part(geohash, 0, 2)}#{suffix}"
        BillBored.Stubs.Redix.command(["SET", key, :erlang.term_to_binary(marker)])
      end

      commands =
        ["f0", "f2", "f8", "dp", "dr", "dx", "dq", "dw"]
        |> Enum.map(&(["SET", "marker:#{&1}#{suffix}", :erlang.term_to_binary(nil)]))
      {:ok, _} = BillBored.Stubs.Redix.pipeline(commands)

      {:ok, all_keys} = BillBored.Stubs.Redix.command(["KEYS", "*"])
      store_redix_fixture(all_keys, @filter_fixture)
    end
  end

  defp start_redix(_context \\ %{}) do
    {:ok, redix_pid} = BillBored.Stubs.Redix.start_link()
    BillBored.Stubs.Redix.use(redix_pid)

    %{redix_pid: redix_pid}
  end

  defp insert_keys(_context) do
    commands =
      [
        "dn",
        "dr",
        "f2",
        "dr:types=event",
        "f2vv",
        "f2vv:flags=nopaid",
        "zz"
      ]
      |> Enum.map(&(["SET", "marker:#{&1}", ""]))

    {:ok, _} = BillBored.Stubs.Redix.pipeline(commands)
    :ok
  end

  defp create_posts(_context) do
    location = %BillBored.Geo.Point{lat: 40.7142715, long: -74.0059662}
    radius = 700_000

    now = DateTime.utc_now()

    p1 = insert(
      :post, title: "New York", inserted_at: Timex.shift(now, minutes: -1),
      updated_at: ~U[2020-05-01 00:00:00Z], location: %BillBored.Geo.Point{lat: 40.7142715, long: -74.0059662}
    )

    p2 = insert(
      :post, type: "event", title: "Nashville", inserted_at: now,
      updated_at: ~U[2020-05-01 00:00:00Z], location: %BillBored.Geo.Point{lat: 36.174465, long: -86.767960}
    )
    insert(:event, post: p2, date: Timex.shift(now, hours: -5))

    p3 = insert(
      :post, type: "event", title: "Charlotte", inserted_at: now,
      updated_at: ~U[2020-05-10 00:00:00Z], location: %BillBored.Geo.Point{lat: 35.2270889, long: -80.843132}
    )
    insert(:event, post: p3, price: 0, date: Timex.shift(now, hours: 1))

    p4 = insert(
      :post, title: "Ottawa", inserted_at: Timex.shift(now, minutes: -5),
      updated_at: ~U[2020-05-01 00:00:00Z], location: %BillBored.Geo.Point{lat: 45.411171, long: -75.6981201}
    )
    p5 = insert(
      :post, type: "vote", title: "Quebec", inserted_at: now,
      updated_at: ~U[2020-05-01 00:00:00Z], location: %BillBored.Geo.Point{lat: 46.8122787, long: -71.2145386}
    )

    %{location: location, radius: radius, posts: [p1, p2, p3, p4, p5]}
  end

  defp store_redix_fixture(keys, path) do
    commands = Enum.map(keys, &(["GET", &1]))
    {:ok, results} = BillBored.Stubs.Redix.pipeline(commands)

    data = Enum.zip(keys, results) |> Enum.into(%{}) |> :erlang.term_to_binary()
    File.write!(path, data)
  end

  defp load_redix_fixture(path) do
    commands =
      :erlang.binary_to_term(File.read!(path))
      |> Enum.map(fn {key, value} ->
        ["SET", key, value]
      end)

    {:ok, _} = BillBored.Stubs.Redix.pipeline(commands)
  end
end
