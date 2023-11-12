defmodule AlleventsTest do
  use BillBored.DataCase, async: true
  import Ecto.Query

  @fixtures_path "#{File.cwd!()}/test/fixtures"

  describe "upsert_events/1" do
    setup do
      with {:ok, json} <- File.read("#{@fixtures_path}/allevents/events.json"),
           {:ok, events} <- Jason.decode(json) do
        %{events: events}
      end
    end

    test "inserts valid events", %{events: [e1, _e2, e3, e4, _e5, _e6] = events} do
      event_sync = insert(:event_synchronization, event_provider: "allevents")
      result = Allevents.upsert_events(events, event_sync)

      event_sync = Repo.preload(event_sync, :provider_events)

      assert sorted_by(Enum.map(event_sync.provider_events, & &1.data), "event_id") == [
               e1,
               e3,
               e4
             ]

      assert %{
               failed_events_count: 0,
               invalid_events: [{"2", _}, {"5", _}, {"6", _}],
               updated_events_count: 3,
               updated_posts_count: 3,
               updated_users_count: 2,
               updated_posts: updated_posts
             } = result

      users = Repo.all(from u in BillBored.User, order_by: [asc: :provider_id])

      assert [
               %{provider_id: "host-ae-1001", username: "host-ae-1001", id: art_author_id},
               %{
                 provider_id: "venue-ae-london-5150244-014458",
                 username: "venue-ae-london-5150244-014458",
                 id: yoga_author_id
               }
             ] = users

      posts = Repo.all(from u in BillBored.Post, order_by: [asc: :provider_id])

      assert sorted_ids(updated_posts) == sorted_ids(posts)

      assert [
               %{
                 id: art_post_id,
                 type: "event",
                 author_id: ^art_author_id,
                 title: "Art event",
                 body: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.496639251708984,
                   long: -0.17217999696731567
                 },
                 location_geohash: 553_585_228_633_271_910,
                 event_provider: "allevents",
                 provider_id: "1",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/1"]
               },
               %{
                 id: yoga_post_id,
                 type: "event",
                 author_id: ^yoga_author_id,
                 title: "Yoga event",
                 body: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.502437591552734,
                   long: -0.14457829296588898
                 },
                 location_geohash: 553_585_238_838_333_597,
                 event_provider: "allevents",
                 provider_id: "3",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/3"]
               },
               %{
                 id: festival_post_id,
                 type: "event",
                 author_id: ^art_author_id,
                 title: "Festival event",
                 body: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.49580764770508,
                   long: -0.13944000005722046
                 },
                 location_geohash: 553_585_239_347_116_225,
                 event_provider: "allevents",
                 provider_id: "4",
                 provider_urls: ["https://cdn-az.allevents.in/events/thumbs/4"]
               }
             ] = posts

      events = Repo.all(from u in BillBored.Event, order_by: [asc: :provider_id])

      assert [
               %{
                 post_id: ^art_post_id,
                 title: "Art event",
                 categories: ["art", "fine-arts"],
                 date: ~U[2020-02-09 10:00:00.000000Z],
                 other_date: ~U[2020-02-09 16:30:00.000000Z],
                 location: %BillBored.Geo.Point{
                   lat: 51.496639251708984,
                   long: -0.17217999696731567
                 },
                 event_provider: "allevents",
                 provider_id: "1",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/1"],
                 buy_ticket_link: "https://allevents.in/london/1",
                 price: nil,
                 currency: nil
               },
               %{
                 post_id: ^yoga_post_id,
                 title: "Yoga event",
                 categories: ["health-wellness", "workshops"],
                 date: ~U[2020-02-09 10:30:00.000000Z],
                 other_date: ~U[2020-02-09 12:30:00.000000Z],
                 location: %BillBored.Geo.Point{
                   lat: 51.502437591552734,
                   long: -0.14457829296588898
                 },
                 event_provider: "allevents",
                 provider_id: "3",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/3"],
                 buy_ticket_link: "https://allevents.in/london/3",
                 price: 60.0,
                 currency: "GBP"
               },
               %{
                 post_id: ^festival_post_id,
                 title: "Festival event",
                 categories: ["entertainment", "music", "festivals", "meetups"],
                 date: ~U[2020-02-11 18:00:00.000000Z],
                 other_date: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.49580764770508,
                   long: -0.13944000005722046
                 },
                 event_provider: "allevents",
                 provider_id: "4",
                 provider_urls: ["https://cdn-az.allevents.in/events/thumbs/4"],
                 buy_ticket_link: "https://allevents.in/london/4",
                 price: nil,
                 currency: nil
               }
             ] = events
    end

    test "updates existing events", %{events: [e1, e2, e3, e4, e5, e6] = events} do
      Allevents.upsert_events(events)

      e1 = Map.merge(e1, %{"eventname" => "Updated art event"})

      e3 = Map.merge(e3, %{"owner_id" => "5555", "categories" => ["Yoga"]})

      e4 =
        Map.merge(e4, %{
          "tickets" => %{"min_ticket_price" => 15, "ticket_currency" => "GBP"},
          "end_time" => 1_581_444_060
        })

      event_sync = insert(:event_synchronization, event_provider: "allevents")
      result = Allevents.upsert_events([e1, e2, e3, e4, e5, e6], event_sync)

      event_sync = Repo.preload(event_sync, :provider_events)

      assert sorted_by(Enum.map(event_sync.provider_events, & &1.data), "event_id") == [
               e1,
               e3,
               e4
             ]

      assert %{
               failed_events_count: 0,
               invalid_events: [{"2", _}, {"5", _}, {"6", _}],
               updated_events_count: 3,
               updated_posts_count: 3,
               updated_users_count: 2,
               updated_posts: updated_posts
             } = result

      users = Repo.all(from u in BillBored.User, order_by: [asc: :provider_id])

      assert [
               %{provider_id: "host-ae-1001", username: "host-ae-1001", id: art_author_id},
               %{provider_id: "host-ae-5555", username: "host-ae-5555", id: new_author_id},
               %{
                 provider_id: "venue-ae-london-5150244-014458",
                 username: "venue-ae-london-5150244-014458",
                 id: yoga_author_id
               }
             ] = users

      posts = Repo.all(from u in BillBored.Post, order_by: [asc: :provider_id])

      assert sorted_ids(updated_posts) == sorted_ids(posts)

      assert [
               %{
                 id: art_post_id,
                 type: "event",
                 author_id: ^art_author_id,
                 title: "Updated art event",
                 body: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.496639251708984,
                   long: -0.17217999696731567
                 },
                 location_geohash: 553_585_228_633_271_910,
                 event_provider: "allevents",
                 provider_id: "1",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/1"]
               },
               %{
                 id: yoga_post_id,
                 type: "event",
                 author_id: ^new_author_id,
                 title: "Yoga event",
                 body: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.502437591552734,
                   long: -0.14457829296588898
                 },
                 location_geohash: 553_585_238_838_333_597,
                 event_provider: "allevents",
                 provider_id: "3",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/3"]
               },
               %{
                 id: festival_post_id,
                 type: "event",
                 author_id: ^art_author_id,
                 title: "Festival event",
                 body: nil,
                 location: %BillBored.Geo.Point{
                   lat: 51.49580764770508,
                   long: -0.13944000005722046
                 },
                 location_geohash: 553_585_239_347_116_225,
                 event_provider: "allevents",
                 provider_id: "4",
                 provider_urls: ["https://cdn-az.allevents.in/events/thumbs/4"]
               }
             ] = posts

      events = Repo.all(from u in BillBored.Event, order_by: [asc: :provider_id])

      assert [
               %{
                 post_id: ^art_post_id,
                 title: "Updated art event",
                 categories: ["art", "fine-arts"],
                 date: ~U[2020-02-09 10:00:00.000000Z],
                 other_date: ~U[2020-02-09 16:30:00.000000Z],
                 location: %BillBored.Geo.Point{
                   lat: 51.496639251708984,
                   long: -0.17217999696731567
                 },
                 event_provider: "allevents",
                 provider_id: "1",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/1"],
                 buy_ticket_link: "https://allevents.in/london/1",
                 price: nil,
                 currency: nil
               },
               %{
                 post_id: ^yoga_post_id,
                 title: "Yoga event",
                 categories: ["yoga"],
                 date: ~U[2020-02-09 10:30:00.000000Z],
                 other_date: ~U[2020-02-09 12:30:00.000000Z],
                 location: %BillBored.Geo.Point{
                   lat: 51.502437591552734,
                   long: -0.14457829296588898
                 },
                 event_provider: "allevents",
                 provider_id: "3",
                 provider_urls: ["https://cdn-az.allevents.in/events/banners/3"],
                 buy_ticket_link: "https://allevents.in/london/3",
                 price: 60.0,
                 currency: "GBP"
               },
               %{
                 post_id: ^festival_post_id,
                 title: "Festival event",
                 categories: ["entertainment", "music", "festivals", "meetups"],
                 date: ~U[2020-02-11 18:00:00.000000Z],
                 other_date: ~U[2020-02-11 18:01:00.000000Z],
                 location: %BillBored.Geo.Point{
                   lat: 51.49580764770508,
                   long: -0.13944000005722046
                 },
                 event_provider: "allevents",
                 provider_id: "4",
                 provider_urls: ["https://cdn-az.allevents.in/events/thumbs/4"],
                 buy_ticket_link: "https://allevents.in/london/4",
                 price: 15.0,
                 currency: "GBP"
               }
             ] = events
    end
  end
end
