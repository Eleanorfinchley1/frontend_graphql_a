defmodule BillBored.GeoTest do
  use BillBored.DataCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import Distance.GreatCircle, only: [distance: 2]
  alias BillBored.Place

  setup_all do
    HTTPoison.start()
  end

  test "fake" do
    coords = {30.7008, 76.7885}

    use_cassette "google_place_chandigarh" do
      assert {:ok, %Place{} = random_place} = BillBored.Geo.fake_place(coords)
      assert random_place.id
      assert %BillBored.Geo.Point{} = random_place.location
    end

    assert places =
             Place
             |> Repo.all()
             |> Enum.map(fn %{location: %BillBored.Geo.Point{lat: lat, long: long}} = place ->
               %{place | distance: distance(coords, {lat, long})}
             end)

    assert length(places) == 20

    # assert Enum.all?(places, &(&1.distance > 800 and &1.distance < 10000))
    assert Enum.all?(places, &(&1.distance > 0 and &1.distance < 10000))
  end
end
