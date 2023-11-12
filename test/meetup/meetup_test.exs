defmodule MeetupTest do
  use BillBored.DataCase, async: true
  import Ecto.Query

  @fixtures_path "#{File.cwd!()}/test/fixtures"

  describe "upsert_events/1" do
    setup do
      with {:ok, json} <- File.read("#{@fixtures_path}/meetup/events.json"),
           {:ok, events} <- Jason.decode(json) do
        %{events: events}
      end
    end

    test "inserts valid events", %{events: [e1, _e2, e3, e4, _e5, _e6] = events} do
      event_sync = insert(:event_synchronization, event_provider: "meetup")
      result = Meetup.upsert_events(events, event_sync)

      event_sync = Repo.preload(event_sync, :provider_events)

      assert sorted_by(Enum.map(event_sync.provider_events, & &1.data), "id") == [
               e1,
               e3,
               e4
             ]

      assert %{
               failed_events_count: 0,
               invalid_events: [{2, _}, {5, _}, {6, _}],
               updated_events_count: 3,
               updated_posts_count: 3,
               updated_users_count: 2,
               updated_posts: updated_posts
             } = result

      users = Repo.all(from u in BillBored.User, order_by: [asc: :provider_id])

      assert [
               %{
                 provider_id: "group-1001",
                 username: "group-tech-group-1001",
                 id: tech_author_id
               },
               %{
                 provider_id: "host-2001",
                 username: "robert-of-music-group-2001",
                 id: robert_id
               }
             ] = users

      posts = Repo.all(from u in BillBored.Post, order_by: [asc: :provider_id])
      assert sorted_ids(updated_posts) == sorted_ids(posts)

      assert [
               %{
                 id: tech_post_id,
                 type: "event",
                 author_id: ^tech_author_id,
                 title: "Tech event",
                 body: "Tech event body",
                 location: %BillBored.Geo.Point{lat: 51.4900016784668, long: -0.15000000596046448},
                 location_geohash: 553_585_233_806_500_522,
                 event_provider: "meetup",
                 provider_id: "1",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ]
               },
               %{
                 id: music_post_id,
                 type: "event",
                 author_id: ^robert_id,
                 title: "Music event",
                 body: "Music event body",
                 location: %BillBored.Geo.Point{
                   lat: 51.52000045776367,
                   long: -0.10000000149011612
                 },
                 location_geohash: 553_586_010_946_906_265,
                 event_provider: "meetup",
                 provider_id: "3",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ]
               },
               %{
                 id: generic_post_id,
                 type: "event",
                 author_id: ^robert_id,
                 title: "Uncategorized event",
                 body: "Generic event body",
                 location: %BillBored.Geo.Point{lat: 51.5, long: -0.12999999523162842},
                 location_geohash: 553_585_263_741_402_446,
                 event_provider: "meetup",
                 provider_id: "4",
                 provider_urls: ["https://secure.meetupstatic.com/photos/3.jpeg"]
               }
             ] = posts

      events = Repo.all(from u in BillBored.Event, order_by: [asc: :provider_id])

      assert [
               %{
                 post_id: ^tech_post_id,
                 title: "Tech event",
                 categories: ["tech"],
                 date: ~U[2020-03-16 19:00:00.000000Z],
                 other_date: ~U[2020-03-16 21:00:00.000000Z],
                 location: %BillBored.Geo.Point{lat: 51.4900016784668, long: -0.15000000596046448},
                 event_provider: "meetup",
                 provider_id: "1",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ],
                 buy_ticket_link: "https://www.meetup.com/events/1/",
                 price: nil,
                 currency: nil
               },
               %{
                 post_id: ^music_post_id,
                 title: "Music event",
                 categories: ["music"],
                 date: ~U[2020-02-28 20:00:00.000000Z],
                 other_date: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.52000045776367,
                   long: -0.10000000149011612
                 },
                 event_provider: "meetup",
                 provider_id: "3",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ],
                 buy_ticket_link: "https://www.meetup.com/events/3/",
                 price: 28.0,
                 currency: "GBP"
               },
               %{
                 post_id: ^generic_post_id,
                 title: "Uncategorized event",
                 categories: [],
                 date: ~U[2020-02-28 20:00:00.000000Z],
                 other_date: ~U[2020-02-29 03:30:00.000000Z],
                 location: %BillBored.Geo.Point{lat: 51.5, long: -0.12999999523162842},
                 event_provider: "meetup",
                 provider_id: "4",
                 provider_urls: ["https://secure.meetupstatic.com/photos/3.jpeg"],
                 buy_ticket_link: "https://www.meetup.com/events/4/",
                 price: nil,
                 currency: nil
               }
             ] = events
    end

    test "updates existing events", %{events: [e1, e2, e3, e4, e5, e6] = events} do
      Meetup.upsert_events(events)

      e1 = Map.merge(e1, %{"description" => "Updated tech event body"})

      e3 =
        Map.merge(e3, %{
          "event_hosts" => [%{"id" => 2005, "name" => "Михаил", "role" => "organize"}]
        })

      e4 =
        Map.merge(e4, %{
          "fee" => %{"amount" => 15, "currency" => "USD"},
          "duration" => 3_600_000,
          "group" => Map.merge(e4["group"], %{"category" => %{"shortname" => "fun"}})
        })

      event_sync = insert(:event_synchronization, event_provider: "meetup")
      result = Meetup.upsert_events([e1, e2, e3, e4, e5, e6], event_sync)

      event_sync = Repo.preload(event_sync, :provider_events)

      assert sorted_by(Enum.map(event_sync.provider_events, & &1.data), "id") == [
               e1,
               e3,
               e4
             ]

      assert %{
               failed_events_count: 0,
               invalid_events: [{2, _}, {5, _}, {6, _}],
               updated_events_count: 3,
               updated_posts_count: 3,
               updated_users_count: 3,
               updated_posts: updated_posts
             } = result

      users = Repo.all(from u in BillBored.User, order_by: [asc: :provider_id])

      assert [
               %{
                 event_provider: "meetup",
                 provider_id: "group-1001",
                 username: "group-tech-group-1001",
                 id: tech_author_id
               },
               %{
                 event_provider: "meetup",
                 provider_id: "host-2001",
                 username: "robert-of-music-group-2001",
                 id: robert_id
               },
               %{
                 event_provider: "meetup",
                 provider_id: "host-2005",
                 username: "mihail-of-music-group-2005",
                 id: jim_id
               }
             ] = users

      posts = Repo.all(from u in BillBored.Post, order_by: [asc: :provider_id])
      assert sorted_ids(updated_posts) == sorted_ids(posts)

      assert [
               %{
                 id: tech_post_id,
                 type: "event",
                 author_id: ^tech_author_id,
                 title: "Tech event",
                 body: "Updated tech event body",
                 location: %BillBored.Geo.Point{lat: 51.4900016784668, long: -0.15000000596046448},
                 location_geohash: 553_585_233_806_500_522,
                 event_provider: "meetup",
                 provider_id: "1",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ]
               },
               %{
                 id: music_post_id,
                 type: "event",
                 author_id: ^jim_id,
                 title: "Music event",
                 body: "Music event body",
                 location: %BillBored.Geo.Point{
                   lat: 51.52000045776367,
                   long: -0.10000000149011612
                 },
                 location_geohash: 553_586_010_946_906_265,
                 event_provider: "meetup",
                 provider_id: "3",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ]
               },
               %{
                 id: generic_post_id,
                 type: "event",
                 author_id: ^robert_id,
                 title: "Uncategorized event",
                 body: "Generic event body",
                 location: %BillBored.Geo.Point{lat: 51.5, long: -0.12999999523162842},
                 location_geohash: 553_585_263_741_402_446,
                 event_provider: "meetup",
                 provider_id: "4",
                 provider_urls: ["https://secure.meetupstatic.com/photos/3.jpeg"]
               }
             ] = posts

      events = Repo.all(from u in BillBored.Event, order_by: [asc: :provider_id])

      assert [
               %{
                 post_id: ^tech_post_id,
                 title: "Tech event",
                 categories: ["tech"],
                 date: ~U[2020-03-16 19:00:00.000000Z],
                 other_date: ~U[2020-03-16 21:00:00.000000Z],
                 location: %BillBored.Geo.Point{lat: 51.4900016784668, long: -0.15000000596046448},
                 event_provider: "meetup",
                 provider_id: "1",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ],
                 buy_ticket_link: "https://www.meetup.com/events/1/",
                 price: nil,
                 currency: nil
               },
               %{
                 post_id: ^music_post_id,
                 title: "Music event",
                 categories: ["music"],
                 date: ~U[2020-02-28 20:00:00.000000Z],
                 other_date: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.52000045776367,
                   long: -0.10000000149011612
                 },
                 event_provider: "meetup",
                 provider_id: "3",
                 provider_urls: [
                   "https://secure.meetupstatic.com/photos/2.jpeg",
                   "https://secure.meetupstatic.com/photos/1.jpeg"
                 ],
                 buy_ticket_link: "https://www.meetup.com/events/3/",
                 price: 28.0,
                 currency: "GBP"
               },
               %{
                 post_id: ^generic_post_id,
                 title: "Uncategorized event",
                 categories: ["fun"],
                 date: ~U[2020-02-28 20:00:00.000000Z],
                 other_date: ~U[2020-02-28 21:00:00.000000Z],
                 location: %BillBored.Geo.Point{lat: 51.5, long: -0.12999999523162842},
                 event_provider: "meetup",
                 provider_id: "4",
                 provider_urls: ["https://secure.meetupstatic.com/photos/3.jpeg"],
                 buy_ticket_link: "https://www.meetup.com/events/4/",
                 price: 15.0,
                 currency: "USD"
               }
             ] = events
    end
  end
end
