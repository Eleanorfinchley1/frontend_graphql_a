defmodule Allevents.APITest do
  use BillBored.DataCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  describe "get_events_by_geo/1" do
    test "London page 1" do
      ExVCR.Config.filter_request_headers("Ocp-Apim-Subscription-Key")
      use_cassette "allevents_get_events_by_geo_london_1" do
        assert {:ok, events, meta} =
                 Allevents.API.get_events_by_geo(%{
                   "longitude" => -0.15,
                   "latitude" => 51.2,
                   "radius" => 1
                 })

        assert 4 == Enum.count(events)

        assert %{
                 next_page_params: %{
                  "longitude" => -0.15,
                  "latitude" => 51.2,
                  "radius" => 1,
                  "page" => 1
                 }
               } == meta
      end
    end

    test "London invalid page" do
      ExVCR.Config.filter_request_headers("Ocp-Apim-Subscription-Key")
      use_cassette "allevents_get_events_by_geo_london_invalid" do
        assert {:error, :invalid_response} =
                 Allevents.API.get_events_by_geo(%{
                  "longitude" => -0.15,
                  "latitude" => 51.2,
                  "radius" => 1,
                  "page" => 1
                 })
      end
    end
  end
end
