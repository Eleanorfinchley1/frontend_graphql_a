defmodule BillBored.Geo.HashTest do
  use BillBored.DataCase, async: true

  describe "estimate_precision_at/2" do
    setup do
      location = %BillBored.Geo.Point{lat: 37.619869594432046, long: -119.61575966280193}

      %{location: location}
    end

    [
      {0, 12},
      {0.005, 12},
      {0.132, 11},
      {20, 7},
      {500_000, 2},
      {1_000_000, 1},
      {999_999_999_999, 1}
    ]
    |> Enum.each(fn {radius, precision} ->
      test "for radius #{radius} returns precision #{precision}", %{location: location} do
        assert unquote(precision) ==
                 BillBored.Geo.Hash.estimate_precision_at(location, unquote(radius))
      end
    end)
  end

  describe "all_within/3" do
    test "correctly wraps over longitude -180" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert ["b", "c", "f", "8", "9", "d", "2", "3", "6", "z", "x", "r"] ==
               BillBored.Geo.Hash.all_within(location, 6_500_000, 1)
    end

    test "correctly wraps over longitude 180" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: 121.95078254117647}

      assert ["v", "y", "z", "t", "w", "x", "m", "q", "r", "b", "8", "2"] ==
               BillBored.Geo.Hash.all_within(location, 6_500_000, 1)
    end

    test "correctly clamps when radius is too large" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert [
               "b",
               "c",
               "f",
               "g",
               "u",
               "v",
               "y",
               "z",
               "8",
               "9",
               "d",
               "e",
               "s",
               "t",
               "w",
               "x",
               "2",
               "3",
               "6",
               "7",
               "k",
               "m",
               "q",
               "r",
               "0",
               "1",
               "4",
               "5",
               "h",
               "j",
               "n",
               "p"
             ] ==
               BillBored.Geo.Hash.all_within(location, 65_000_000, 1)
    end

    test "returns geohash when it is larger that the radius" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert ["9"] ==
               BillBored.Geo.Hash.all_within(location, 300_000, 1)
    end

    test "returns geohashes of different precision" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert ["9q9m8f", "9q9m94", "9q9m8c", "9q9m91"] ==
               BillBored.Geo.Hash.all_within(location, 300, 6)

      assert [
               "9q9m8f5",
               "9q9m8fh",
               "9q9m8fj",
               "9q9m8fn",
               "9q9m8fp",
               "9q9m940",
               "9q9m8cg",
               "9q9m8cu",
               "9q9m8cv",
               "9q9m8cy",
               "9q9m8cz",
               "9q9m91b",
               "9q9m8ce",
               "9q9m8cs",
               "9q9m8ct",
               "9q9m8cw",
               "9q9m8cx",
               "9q9m918",
               "9q9m8c7",
               "9q9m8ck",
               "9q9m8cm",
               "9q9m8cq",
               "9q9m8cr",
               "9q9m912",
               "9q9m8c5",
               "9q9m8ch",
               "9q9m8cj",
               "9q9m8cn",
               "9q9m8cp",
               "9q9m910"
             ] ==
               BillBored.Geo.Hash.all_within(location, 300, 7)

      assert ["9q9m8cw4", "9q9m8cw1"] ==
               BillBored.Geo.Hash.all_within(location, 10, 8)
    end
  end

  describe "all_within_safe/3" do
    test "correctly wraps over longitude -180" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert {:ok, ["b", "c", "f", "8", "9", "d", "2", "3", "6", "z", "x", "r"]} ==
               BillBored.Geo.Hash.all_within_safe(location, 6_500_000, 1)
    end

    test "correctly wraps over longitude 180" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: 121.95078254117647}

      assert {:ok, ["v", "y", "z", "t", "w", "x", "m", "q", "r", "b", "8", "2"]} ==
               BillBored.Geo.Hash.all_within_safe(location, 6_500_000, 1)
    end

    test "correctly clamps when radius is too large" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert {:ok,
              [
                "b",
                "c",
                "f",
                "g",
                "u",
                "v",
                "y",
                "z",
                "8",
                "9",
                "d",
                "e",
                "s",
                "t",
                "w",
                "x",
                "2",
                "3",
                "6",
                "7",
                "k",
                "m",
                "q",
                "r",
                "0",
                "1",
                "4",
                "5",
                "h",
                "j",
                "n",
                "p"
              ]} ==
               BillBored.Geo.Hash.all_within_safe(location, 65_000_000, 1)
    end

    test "returns geohash when it is larger that the radius" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert {:ok, ["9"]} ==
               BillBored.Geo.Hash.all_within_safe(location, 300_000, 1)
    end

    test "returns geohashes of different precision" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert {:ok, ["9q9m8f", "9q9m94", "9q9m8c", "9q9m91"]} ==
               BillBored.Geo.Hash.all_within_safe(location, 300, 6)

      assert {:ok,
              [
                "9q9m8f5",
                "9q9m8fh",
                "9q9m8fj",
                "9q9m8fn",
                "9q9m8fp",
                "9q9m940",
                "9q9m8cg",
                "9q9m8cu",
                "9q9m8cv",
                "9q9m8cy",
                "9q9m8cz",
                "9q9m91b",
                "9q9m8ce",
                "9q9m8cs",
                "9q9m8ct",
                "9q9m8cw",
                "9q9m8cx",
                "9q9m918",
                "9q9m8c7",
                "9q9m8ck",
                "9q9m8cm",
                "9q9m8cq",
                "9q9m8cr",
                "9q9m912",
                "9q9m8c5",
                "9q9m8ch",
                "9q9m8cj",
                "9q9m8cn",
                "9q9m8cp",
                "9q9m910"
              ]} ==
               BillBored.Geo.Hash.all_within_safe(location, 300, 7)

      assert {:ok, ["9q9m8cw4", "9q9m8cw1"]} ==
               BillBored.Geo.Hash.all_within_safe(location, 10, 8)
    end

    test "returns error when precision is unsafe" do
      location = %BillBored.Geo.Point{lat: 37.53784772352942, long: -121.95078254117647}

      assert {:error, :unsafe_precision} ==
               BillBored.Geo.Hash.all_within_safe(location, 1000, 8)

      assert {:error, :unsafe_precision} ==
               BillBored.Geo.Hash.all_within_safe(location, 300, 9)

      assert {:error, :unsafe_precision} ==
               BillBored.Geo.Hash.all_within_safe(location, 10, 12)
    end
  end
end
