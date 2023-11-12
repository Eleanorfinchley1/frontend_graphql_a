defmodule EventfulTest do
  use BillBored.DataCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  doctest Eventful, import: true

  setup_all do
    HTTPoison.start()
  end

  test "search_events!/1" do
    use_cassette "eventful_search_events_vancourver" do
      assert %HTTPoison.Response{status_code: 200, body: body} =
               Eventful.search_events!(%{
                 "keyword" => "bored",
                 "location" => "vancouver",
                 "within" => "10",
                 "units" => "km"
               })

      assert %{
               "events" => %{"event" => events},
               "first_item" => nil,
               "last_item" => nil,
               "page_count" => "1271",
               "page_items" => nil,
               "page_number" => "1",
               "page_size" => "10",
               "search_time" => "0.106",
               "total_items" => "12701"
             } = body

      assert is_list(events)
      assert length(events) == 10
    end
  end

  test "search_events_for_location!/2" do
    use_cassette "eventful_search_events_for_location_moscow" do
      location = {%BillBored.Geo.Point{lat: 55.7558, long: 37.6173}, 5000}

      assert {^location, _page = 1,
              %HTTPoison.Response{status_code: 200, body: body, request: request}} =
               Eventful.search_events_for_location!(location, 1, %{
                 "category" => "music",
                 "date" => Eventful.date_range(30, ~D[2019-12-01])
               })

      assert %URI{
               authority: "api.eventful.com",
               fragment: nil,
               host: "api.eventful.com",
               path: "/json/events/search/",
               port: 443,
               query: query,
               scheme: "https",
               userinfo: nil
             } = URI.parse(request.url)

      assert %{
               "app_key" => "4wLznrDmn2rCW2x8",
               "category" => "music",
               "date" => "2019120100-2019123100",
               "include" => "categories,price,tickets,links",
               "location" => "55.7558,37.6173",
               "page_number" => "1",
               "units" => "km",
               "within" => "5"
             } = URI.decode_query(query)

      assert %{
               "events" => %{"event" => _events},
               "first_item" => nil,
               "last_item" => nil,
               "page_count" => "1",
               "page_items" => nil,
               "page_number" => "1",
               "page_size" => "10",
               "search_time" => "0.152",
               "total_items" => "5"
             } = body
    end
  end

  test "persist_events/1" do
    use_cassette "eventful_search_events_for_location_moscow" do
      location = {%BillBored.Geo.Point{lat: 55.7558, long: 37.6173}, 5000}

      assert {^location, _page = 1,
              %HTTPoison.Response{status_code: 200, body: %{"events" => %{"event" => events}}}} =
               Eventful.search_events_for_location!(location, 1, %{
                 "category" => "music",
                 "date" => Eventful.date_range(30, ~D[2019-12-01])
               })

      posts = Eventful.persist_events(events)

      assert length(posts) == length(events)
      assert length(posts) == 5

      assert %{
               location: %BillBored.Geo.Point{lat: 55.7520233, long: 37.6174994},
               location_geohash: 1_152_921_504_606_846_975
             } = Enum.at(posts, 0)

      :timer.sleep(1000)

      assert [] == Eventful.persist_events(events, 1)
    end
  end

  test "has_recent_searches?/1" do
    point = fn {lat, long} ->
      %BillBored.Geo.Point{lat: lat, long: long}
    end

    day_ago = fn ->
      DateTime.add(DateTime.utc_now(), -24 * 60 * 60)
    end

    Repo.insert_all("eventful_requests", [
      %{datetime: day_ago.(), location: point.({55.7558, 37.6173}), radius: 1000}
    ])

    Repo.insert_all("eventful_requests", [
      %{datetime: day_ago.(), location: point.({55.7558, 37.6173}), radius: 40000}
    ])

    Repo.insert_all("eventful_requests", [
      %{datetime: day_ago.(), location: point.({55.7558, 37.6173}), radius: 5000}
    ])

    Repo.insert_all("eventful_requests", [
      %{datetime: DateTime.utc_now(), location: point.({55.7558, 37.6173}), radius: 10000}
    ])

    Repo.insert_all("eventful_requests", [
      %{datetime: DateTime.utc_now(), location: point.({55.7558, 37.6173}), radius: 5000}
    ])

    assert Eventful.has_recent_searches?({point.({55.7558, 37.6173}), _radius = 5000})
    assert 2 == "eventful_requests" |> select([r], count(r.location)) |> Repo.one()
  end

  test "record_search/1" do
    Eventful.record_search({
      _point = %BillBored.Geo.Point{lat: 55.7558, long: 37.6173},
      _radius = 5000
    })

    assert %{radius: 5000, location: %BillBored.Geo.Point{lat: 55.7558, long: 37.6173}} ==
             "eventful_requests"
             |> select([:radius, :location])
             |> Repo.one()
  end
end
