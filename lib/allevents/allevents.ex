defmodule Allevents do
  alias BillBored.{EventSynchronization, EventSynchronizations}

  require Logger
  import BillBored.ServiceRegistry, only: [service: 1]

  @empty_user_attributes %{
    avatar: "",
    avatar_thumbnail: "",
    password: "",
    is_superuser: false,
    first_name: "",
    last_name: "",
    email: "",
    is_staff: false,
    is_active: false,
    bio: "",
    sex: "",
    prefered_radius: 0,
    country_code: "",
    enable_push_notifications: false,
    area: ""
  }

  @batch_size 100
  @event_provider "allevents"
  @recent_shift [hours: -12]

  def synchronize_events(location) do
    with {_point, _radius} = sanitized_location <- sanitize_search_location(location),
         :ok <- check_recent_synchronizations(sanitized_location) do
      {:ok, event_synchronization} = create_event_synchronization(sanitized_location)

      case do_synchronize_events(sanitized_location, event_synchronization) do
        {:ok, result} ->
          Logger.debug(
            "Allevents events synchronization completed at #{inspect(sanitized_location)}"
          )

          service(BillBored.CachedPosts.Server).notify()

          {:ok, event_synchronization} = EventSynchronizations.complete(event_synchronization)
          {:ok, event_synchronization, result}

        error ->
          Logger.error(
            "Failed to synchronize Allevents events at #{inspect(sanitized_location)}: #{
              inspect(error)
            }"
          )

          EventSynchronizations.fail(event_synchronization)
          error
      end
    end
  end

  defp sanitize_search_location({%BillBored.Geo.Point{} = point, radius}) do
    {point, min(max(1000, radius), 20_000)}
  end

  defp sanitize_search_location(_), do: {:error, :invalid_search_location}

  defp check_recent_synchronizations(location) do
    datetime = Timex.shift(DateTime.utc_now(), @recent_shift)

    EventSynchronizations.delete_old(@event_provider, datetime)

    %{completed_count: completed, pending_count: pending} =
      EventSynchronizations.count_recent(@event_provider, location, datetime)

    cond do
      pending > 0 -> :sync_is_in_progress
      completed > 0 -> :recently_synced
      true -> :ok
    end
  end

  defp create_event_synchronization({%BillBored.Geo.Point{} = point, radius}) do
    EventSynchronizations.create(%{
      event_provider: @event_provider,
      started_at: DateTime.utc_now(),
      location: point,
      radius: radius,
      status: "pending"
    })
  end

  @summary_counters [
    :updated_users_count,
    :updated_posts_count,
    :updated_events_count,
    :failed_events_count
  ]

  defp do_synchronize_events(
         {%BillBored.Geo.Point{lat: lat, long: long}, radius},
         event_synchronization
       ) do
    try do
      events_stream =
        Stream.resource(
          fn ->
            %{
              "longitude" => long,
              "latitude" => lat,
              "radius" => round(Float.ceil(BillBored.Geo.meters_to_miles(radius)))
            }
          end,
          fn
            nil ->
              {:halt, nil}

            params ->
              case Allevents.API.get_events_by_geo(params) do
                {:ok, events, %{next_page_params: next_params}} ->
                  {[events], next_params}

                error ->
                  Logger.error("Allevents API error: #{inspect(error)}")
                  {:halt, nil}
              end
          end,
          fn _ -> nil end
        )

      result =
        events_stream
        |> summarize(
          [counters: @summary_counters, lists: [:updated_posts, :invalid_events]],
          &upsert_events(&1, event_synchronization)
        )

      {:ok, result}
    catch
      error ->
        Logger.error("Failed to synchronize Allevents events: #{inspect(error)}")
        {:error, error}
    end
  end

  def upsert_events(events, event_synchronization \\ nil) do
    {prepared_events, errors} = prepare_events(events)

    prepared_events
    |> Enum.chunk_every(@batch_size)
    |> summarize([counters: @summary_counters, lists: [:updated_posts]], fn chunk ->
      result =
        Ecto.Multi.new()
        |> upsert_provider_events(chunk, event_synchronization)
        |> upsert_users(chunk)
        |> upsert_posts(chunk)
        |> upsert_post_events(chunk)
        |> Repo.transaction()

      with {:ok,
            %{
              insert_owners: {chunk_updated_users, _},
              insert_posts: {chunk_updated_posts, posts},
              insert_events: {chunk_updated_events, _}
            }} <- result do
        %{
          updated_users_count: chunk_updated_users,
          updated_posts_count: chunk_updated_posts,
          updated_events_count: chunk_updated_events,
          updated_posts: posts
        }
      else
        _ ->
          %{failed_events: Enum.count(chunk)}
      end
    end)
    |> Map.put(:invalid_events, errors)
  end

  def prepare_events(events) do
    {prepared_events, errors} =
      events
      |> Enum.reduce({[], []}, fn %{"event_id" => provider_event_id} = provider_event,
                                  {events, errors} ->
        with {:ok, %BillBored.Geo.Point{lat: lat, long: lon} = location} <-
               get_event_location(provider_event),
             {:ok, urls} <- get_event_urls(provider_event),
             {:ok, owner} <- build_event_owner(provider_event),
             {:ok, post} <- build_event_post(provider_event),
             {:ok, event} <- build_event(provider_event) do
          common = %{
            location: location,
            provider_urls: urls
          }

          new_event = %{
            owner: owner,
            post:
              Map.put(
                Map.merge(post, common),
                :location_geohash,
                BillBored.Geo.Hash.to_integer(Geohash.encode(lat, lon, 12))
              ),
            event: Map.merge(event, common),
            provider_event: %{
              event_provider: @event_provider,
              provider_id: to_string(provider_event_id),
              data: provider_event,
              inserted_at: DateTime.utc_now(),
              updated_at: DateTime.utc_now()
            }
          }

          {[new_event | events], errors}
        else
          error ->
            {events, [{provider_event_id, error} | errors]}
        end
      end)

    {Enum.reverse(prepared_events), Enum.reverse(errors)}
  end

  defp summarize(enumerable, options, fun) do
    counters = Keyword.get(options, :counters, [])
    lists = Keyword.get(options, :lists, [])

    initial = Enum.reduce(counters, %{}, fn k, acc -> Map.put(acc, k, 0) end)
    initial = Enum.reduce(lists, initial, fn k, acc -> Map.put(acc, k, []) end)

    result =
      Enum.reduce(enumerable, initial, fn el, acc ->
        fun.(el)
        |> Enum.reduce(acc, fn {key, value}, acc ->
          if key in lists do
            case Map.get(acc, key) do
              list when is_list(list) -> Map.put(acc, key, [value | list])
              _ -> Map.put(acc, key, [value])
            end
          else
            Map.put(acc, key, Map.get(acc, key, 0) + value)
          end
        end)
      end)

    Enum.reduce(lists, result, fn list, acc ->
      reversed = List.flatten(Enum.reverse(Map.get(acc, list)))
      Map.put(acc, list, reversed)
    end)
  end

  defp upsert_provider_events(multi, _chunk, nil), do: multi

  defp upsert_provider_events(multi, chunk, %EventSynchronization{
         event_provider: @event_provider,
         id: event_sync_id
       }) do
    Ecto.Multi.run(multi, :insert_provider_events, fn _repo, _ ->
      provider_events =
        Enum.map(
          chunk,
          &Map.merge(&1[:provider_event], %{event_synchronization_id: event_sync_id})
        )

      {:ok,
       Repo.insert_all(
         BillBored.EventProviderEvent,
         provider_events,
         returning: true,
         on_conflict: {:replace, [:data]},
         conflict_target: [:event_provider, :provider_id]
       )}
    end)
  end

  defp upsert_users(multi, chunk) do
    Ecto.Multi.run(multi, :insert_owners, fn _repo, _ ->
      owners = Enum.map(chunk, & &1[:owner]) |> Enum.uniq_by(& &1[:provider_id])

      {:ok,
       Repo.insert_all(
         BillBored.User,
         owners,
         returning: true,
         # we rely on returned ids
         on_conflict: {:replace, [:provider_id]},
         conflict_target: [:event_provider, :provider_id]
       )}
    end)
  end

  def upsert_posts(multi, chunk) do
    Ecto.Multi.run(multi, :insert_posts, fn _repo, %{insert_owners: {_, users}} ->
      users_map = users |> Enum.map(&{&1.provider_id, &1.id}) |> Enum.into(%{})

      posts =
        Enum.map(chunk, fn %{owner: owner, post: post} ->
          Map.put(post, :author_id, Map.get(users_map, owner[:provider_id]))
        end)

      {:ok,
       Repo.insert_all(
         BillBored.Post,
         posts,
         returning: true,
         on_conflict:
           {:replace,
            [:updated_at, :title, :location, :location_geohash, :body, :provider_urls, :author_id]},
         conflict_target: [:event_provider, :provider_id]
       )}
    end)
  end

  defp upsert_post_events(multi, chunk) do
    Ecto.Multi.run(multi, :insert_events, fn _repo, %{insert_posts: {_, posts}} ->
      events =
        for {event, %{id: post_id}} <- Stream.zip(Stream.map(chunk, & &1[:event]), posts) do
          Map.put(event, :post_id, post_id)
        end

      {:ok,
       Repo.insert_all(
         BillBored.Event,
         events,
         returning: true,
         on_conflict:
           {:replace,
            [
              :location,
              :title,
              :categories,
              :updated_at,
              :date,
              :other_date,
              :provider_urls,
              :price,
              :currency,
              :buy_ticket_link
            ]},
         conflict_target: [:event_provider, :provider_id]
       )}
    end)
  end

  defp build_event_owner(%{"venue" => venue} = event) do
    owner_id = event["owner_id"]

    provider_id =
      if owner_id && String.length(owner_id) > 0 do
        "host-ae-#{owner_id}"
      else
        "venue-ae-#{make_venue_hash(venue)}"
      end

    result =
      Map.merge(@empty_user_attributes, %{
        event_provider: @event_provider,
        provider_id: provider_id,
        username: provider_id,
        date_joined: DateTime.utc_now()
      })

    {:ok, result}
  end

  defp build_event_owner(_event), do: {:error, :invalid_owner}

  defp make_venue_hash(%{"latitude" => lat, "longitude" => lon, "city" => city}) do
    id = "#{Float.round(lat, 5)}#{Float.round(lon, 5)}" |> String.replace(".", "")
    make_slug([city], id)
  end

  defp make_venue_hash(_) do
    "invalid"
  end

  defp make_slug(parts, suffix \\ nil) do
    slug =
      parts
      |> Enum.join(" ")
      |> Slug.slugify(truncate: 100)

    if suffix do
      "#{slug}-#{suffix}"
    else
      slug
    end
  end

  defp get_event_location(%{"venue" => %{"longitude" => lon, "latitude" => lat}} = _event) do
    if valid_location?(lat, lon) do
      {:ok, %BillBored.Geo.Point{lat: lat, long: lon}}
    else
      {:error, :invalid_location}
    end
  end

  defp get_event_location(_event), do: {:error, :invalid_location}

  defp valid_location?(lat, lon), do: lat != 0 and lon != 0

  defp build_event_post(%{"event_id" => event_id} = event) do
    {:ok,
     %{
       type: "event",
       author_id: nil,
       title: event["eventname"],
       body: nil,
       event_provider: @event_provider,
       provider_id: to_string(event_id),
       inserted_at: DateTime.utc_now(),
       updated_at: DateTime.utc_now()
     }}
  end

  defp build_event(%{"event_id" => event_id} = event) do
    with {:ok, price, currency} <- get_event_price(event),
         {:ok, ticket_link} <- get_event_ticket_link(event),
         {:ok, begin_date, end_date} <- get_event_dates(event),
         {:ok, categories} <- get_event_categories(event) do
      {:ok,
       %{
         event_provider: @event_provider,
         provider_id: to_string(event_id),
         post_id: nil,
         title: event["eventname"],
         price: price,
         currency: currency,
         categories: categories,
         # TODO not actually a buy link
         buy_ticket_link: ticket_link,
         # TODO all day
         date: begin_date,
         other_date: end_date,
         inserted_at: DateTime.utc_now(),
         updated_at: DateTime.utc_now()
       }}
    end
  end

  defp build_event(_event), do: {:error, :invalid_event}

  defp get_event_urls(event) do
    urls =
      ["banner_url", "thumb_url"]
      |> Enum.reduce_while([], fn key, acc ->
        case url = event[key] do
          "http" <> _rest ->
            {:halt, [url]}

          _ ->
            {:cont, acc}
        end
      end)

    {:ok, urls}
  end

  defp get_event_categories(%{"categories" => categories}) do
    categories =
      categories
      |> Enum.map(fn cat -> make_slug([cat]) end)

    {:ok, categories}
  end

  defp get_event_categories(_event) do
    {:ok, []}
  end

  defp get_event_dates(%{"start_time" => start_time} = event) do
    with {:ok, begin_date} <- DateTime.from_unix(start_time * 1_000_000, :microsecond),
         {:ok, end_date} <- optional_date(event["end_time"]) do
      {:ok, begin_date, end_date}
    end
  end

  defp get_event_dates(_event), do: {:error, :invalid_dates}

  defp optional_date(nil), do: {:ok, nil}

  defp optional_date(unix) when is_integer(unix),
    do: DateTime.from_unix(unix * 1_000_000, :microsecond)

  defp optional_date(_), do: {:ok, nil}

  defp get_event_price(%{
         "tickets" => %{"min_ticket_price" => min_price, "ticket_currency" => currency}
       })
       when is_float(min_price) do
    with %Money{} = money <- Money.from_float(currency, min_price) do
      {:ok, Decimal.to_float(money.amount), to_string(money.currency)}
    end
  end

  defp get_event_price(%{
         "tickets" => %{"min_ticket_price" => min_price, "ticket_currency" => currency}
       }) do
    with %Money{} = money <- Money.new(currency, min_price) do
      {:ok, Decimal.to_float(money.amount), to_string(money.currency)}
    end
  end

  defp get_event_price(_event) do
    {:ok, nil, nil}
  end

  defp get_event_ticket_link(%{"event_url" => event_url, "tickets" => %{"ticket_url" => ""}}) do
    {:ok, event_url}
  end

  defp get_event_ticket_link(%{"tickets" => %{"has_tickets" => true, "ticket_url" => ticket_url}}) do
    {:ok, ticket_url}
  end

  defp get_event_ticket_link(%{"event_url" => event_url}) do
    {:ok, event_url}
  end

  defp get_event_ticket_link(_event) do
    {:ok, nil}
  end
end
