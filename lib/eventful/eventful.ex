defmodule Eventful do
  @moduledoc false
  alias __MODULE__.API
  import Ecto.Query
  import Geo.PostGIS
  import BillBored.ServiceRegistry, only: [service: 1]
  require Logger

  def search_events!(params) do
    query = URI.encode_query(params)
    API.get!("/events/search/?#{query}", [], timeout: 20_000, recv_timeout: 20_000)
  end

  defp location_to_params({%BillBored.Geo.Point{lat: lat, long: long}, radius}) do
    %{
      "within" => "#{round(radius / 1000)}",
      "units" => "km",
      "location" => "#{lat},#{long}"
    }
  end

  @doc """
  Returns a date range filter acceptable by Eventful

  Example:

      iex> date_range(30, ~D[2019-12-01])
      "2019120100-2019123100"

  """
  def date_range(days, from \\ Date.utc_today()) do
    to = Date.add(from, days)

    [from, to]
    |> Enum.map(fn date -> (date |> Date.to_iso8601() |> String.replace("-", "")) <> "00" end)
    |> Enum.join("-")
  end

  @doc """
  Example usage:

      extra_params = %{
        "category" => "music",
        "date" => date_range(30)
      }

      search_events_for_location!(location, 1, extra_params)
  """
  def search_events_for_location!(location, page \\ 1, extra_params \\ %{}) do
    {location, page,
     location
     |> location_to_params()
     |> Map.merge(extra_params)
     |> Map.put("include", "categories,price,tickets,links")
     |> Map.put("image_sizes", "whiteborder500")
     |> Map.put("page_number", page)
     |> search_events!()}
  end

  def has_more_items?(%{
        "page_count" => page_count,
        "page_number" => page_number
      }) do
    String.to_integer(page_count) > String.to_integer(page_number)
  end

  @spec persist_events([map], integer) :: [%BillBored.Post{}]
  def persist_events(eventful_events, diffing_interval \\ 10_000) when is_list(eventful_events) do
    now = DateTime.utc_now()

    Repo.insert_all(
      "eventful_events",
      Enum.map(eventful_events, &%{id: &1["id"], data: &1, inserted_at: now, updated_at: now}),
      on_conflict: {:replace, [:data, :updated_at]},
      conflict_target: [:id]
    )

    # TODO use evdb as a user
    {_, users} =
      Repo.insert_all(
        BillBored.User,
        eventful_events
        |> Enum.uniq_by(& &1["venue_id"])
        |> Enum.map(fn %{"venue_id" => venue_id} = event ->
          username =
            if name = event["venue_name"] do
              name = Slug.slugify(name, truncate: 18) || "noname"
              "#{name}-#{venue_id}"
            else
              "noname-eventful-venue-#{venue_id}"
            end

          %{
            avatar: "",
            avatar_thumbnail: "",
            password: "",
            is_superuser: false,
            first_name: "",
            last_name: "",
            email: "",
            is_staff: false,
            is_active: false,
            date_joined: DateTime.utc_now(),
            bio: "",
            sex: "",
            prefered_radius: 0,
            country_code: "",
            enable_push_notifications: false,
            area: "",
            username: username,
            eventful_id: venue_id
          }
        end),
        returning: true,
        on_conflict: {:replace, [:username]},
        conflict_target: [:eventful_id]
      )

    mapping_eventful_id_to_user =
      users
      |> Enum.map(&{&1.eventful_id, &1})
      |> Enum.into(%{})

    mapping_user_id_to_user =
      users
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    {_, posts} =
      Repo.insert_all(
        BillBored.Post,
        Enum.map(eventful_events, fn %{
                                       "id" => eventful_id,
                                       "longitude" => long,
                                       "latitude" => lat,
                                       "venue_id" => venue_id
                                     } = event ->
          %{
            type: "event",
            author_id: mapping_eventful_id_to_user[venue_id].id,
            title: event["title"],
            location: %BillBored.Geo.Point{lat: lat, long: long},
            location_geohash: BillBored.Geo.Hash.to_integer(Geohash.encode(lat, long, 12)),
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now(),
            event_provider: "eventful",
            provider_id: eventful_id,
            eventful_id: eventful_id,
            body: event["description"],
            eventful_urls:
              if image_url = get_in(event, ["image", "whiteborder500", "url"]) do
                [image_url]
              end || []
          }
        end),
        returning: true,
        on_conflict:
          {:replace, [:updated_at, :title, :location, :location_geohash, :body, :eventful_urls]},
        conflict_target: [:eventful_id]
      )

    posts = Enum.map(posts, &%{&1 | interests: [], place: nil, polls: [], media_files: []})

    {_, events} =
      Repo.insert_all(
        BillBored.Event,
        posts
        |> Enum.map(& &1.id)
        |> Enum.zip(eventful_events)
        |> Enum.map(fn {post_id,
                        %{
                          "id" => eventful_id,
                          "longitude" => long,
                          "latitude" => lat,
                          "start_time" => start_time
                        } = event} ->
          {:ok, begin_date, 0} = DateTime.from_iso8601(start_time <> "Z")
          begin_date = %{begin_date | microsecond: {0, 6}}

          end_date =
            if stop_time = event["stop_time"] do
              {:ok, end_date, _} = DateTime.from_iso8601(stop_time <> "Z")
              %{end_date | microsecond: {0, 6}}
            end

          price =
            if price = event["price"] do
              case Money.parse(price) do
                %Money{} = price ->
                  price

                {:error, {Money.Invalid, _error}} ->
                  if locale = event["country_abbr2"] do
                    case BillBored.Cldr.Territory.to_currency_code(locale) do
                      {:ok, currency} ->
                        case Money.parse(price, default_currency: currency) do
                          %Money{} = price ->
                            price

                          {:error, reason} ->
                            Logger.error("Failed to parse money:\n\n#{inspect(reason)}")
                            nil
                        end

                      error ->
                        Logger.error("Failed to get currency from locale:\n\n#{inspect(error)}")
                        nil
                    end
                  else
                    Logger.error("Failed to get event.country_abbr2:\n\n#{inspect(event)}")
                    nil
                  end

                {:error, error} ->
                  Logger.error(inspect(error))

                  price
                  |> String.split("-", trim: true)
                  |> hd()
                  |> Money.parse()
                  |> case do
                    %Money{} = price ->
                      Logger.warn("Parsed as #{inspect(price)}")
                      price

                    _other ->
                      nil
                  end
              end
            end

          %{
            eventful_id: eventful_id,
            post_id: post_id,
            location: %BillBored.Geo.Point{lat: lat, long: long},
            title: event["title"],
            inserted_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now(),
            currency: if(price, do: to_string(price.currency)),
            price: if(price, do: Decimal.to_float(price.amount)),
            categories:
              if categories = get_in(event, ["categories", "category"]) do
                Enum.map(categories, & &1["id"])
              end,
            # TODO not actually a buy link
            buy_ticket_link: event["url"],
            # TODO all day
            date: begin_date,
            other_date: end_date,
            eventful_urls:
              if image_url = get_in(event, ["image", "whiteborder500", "url"]) do
                [image_url]
              end || []
          }
        end),
        returning: true,
        on_conflict:
          {:replace,
           [:location, :title, :updated_at, :date, :other_date, :eventful_urls, :price, :currency]},
        conflict_target: [:eventful_id]
      )

    service(BillBored.CachedPosts.Server).notify()

    events = Enum.map(events, &%{&1 | place: nil, attendees: [], media_files: []})

    posts
    |> Enum.zip(events)
    |> Enum.map(fn {post, event} ->
      %{post | author: mapping_user_id_to_user[post.author_id], events: [event]}
    end)
    # TODO this filters old (duplicated) events, seems a bit hacky
    |> Enum.reject(fn %BillBored.Post{inserted_at: inserted_at, updated_at: updated_at} ->
      DateTime.diff(updated_at, inserted_at, :millisecond) > diffing_interval
    end)
  end

  def has_recent_searches?({%BillBored.Geo.Point{} = point, radius}) do
    "eventful_requests"
    |> where([r], r.datetime < ago(12, "hour"))
    |> Repo.delete_all()

    "eventful_requests"
    |> where([r], r.datetime >= ago(12, "hour"))
    |> where([r], st_distance_in_meters(r.location, ^point) + ^radius <= r.radius)
    |> Repo.exists?()
  end

  def record_search({%BillBored.Geo.Point{} = point, radius}) do
    Repo.insert_all("eventful_requests", [
      %{datetime: DateTime.utc_now(), location: point, radius: round(radius)}
    ])
  end
end
