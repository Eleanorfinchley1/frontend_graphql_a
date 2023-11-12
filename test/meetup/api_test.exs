defmodule Meetup.APITest do
  use BillBored.DataCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    :ets.insert(
      Meetup.API.Auth,
      {:auth_info, %{"access_token" => "95d6541de027178705942b1f27981494"}}
    )

    HTTPoison.start()
  end

  describe "find_upcoming_events/1" do
    test "London page 1" do
      use_cassette "meetup_find_upcoming_events_london_1" do
        assert {:ok, events, meta} =
                 Meetup.API.find_upcoming_events(%{
                   "lon" => -0.12574,
                   "page" => 50,
                   "lat" => 51.5085297,
                   "radius" => 1,
                   "fields" =>
                     "featured_photo,group_key_photo,group_photo,event_hosts,group_category,description_images"
                 })

        assert 49 == Enum.count(events)

        assert %{
                 next_page_params: %{
                   "page" => "50",
                   "offset" => "1",
                   "lon" => "-0.12574",
                   "lat" => "51.5085297",
                   "radius" => "1",
                   "fields" =>
                     "featured_photo,group_key_photo,group_photo,event_hosts,group_category,description_images"
                 }
               } == meta
      end
    end

    test "London page 2" do
      use_cassette "meetup_find_upcoming_events_london_2" do
        assert {:ok, events, meta} =
                 Meetup.API.find_upcoming_events(%{
                   "page" => "50",
                   "offset" => "1",
                   "lon" => "-0.12574",
                   "lat" => "51.5085297",
                   "radius" => "1",
                   "fields" =>
                     "featured_photo,group_key_photo,group_photo,event_hosts,group_category,description_images"
                 })

        assert 49 == Enum.count(events)

        assert %{
                 next_page_params: %{
                   "page" => "50",
                   "offset" => "2",
                   "lon" => "-0.12574",
                   "lat" => "51.5085297",
                   "radius" => "1",
                   "fields" =>
                     "featured_photo,group_key_photo,group_photo,event_hosts,group_category,description_images"
                 }
               } == meta
      end
    end

    test "London last page" do
      use_cassette "meetup_find_upcoming_events_london_last" do
        assert {:ok, events, meta} =
                 Meetup.API.find_upcoming_events(%{
                   "page" => "50",
                   "offset" => "54",
                   "lon" => "-0.12574",
                   "lat" => "51.5085297",
                   "radius" => "1",
                   "fields" =>
                     "featured_photo,group_key_photo,group_photo,event_hosts,group_category,description_images"
                 })

        assert 0 == Enum.count(events)

        assert %{
                 next_page_params: nil
               } == meta
      end
    end
  end
end
