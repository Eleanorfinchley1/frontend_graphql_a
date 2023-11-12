defmodule Web.CovidControllerTest do
  use Web.ConnCase, async: false

  import BillBored.Factory

  describe "list_by_country/2" do
    setup do
      ita_location =
        insert(:covid_location,
          country_code: "ITA",
          country: "Italy",
          source_location: %BillBored.Geo.Point{lat: 41.902782, long: 12.496366}
        )

      insert(:covid_case,
        datetime: ~U[2020-03-20 00:00:00.000000Z],
        location:
          insert(:covid_location,
            country_code: "CHN",
            country: "China",
            source_location: %BillBored.Geo.Point{lat: 39.913818, long: 116.363625}
          ),
        cases: 81_250,
        deaths: 3_253,
        recoveries: 71_266,
        active_cases: 6_731
      )

      insert(:covid_case,
        datetime: ~U[2020-03-20 10:15:00.000000Z],
        location: ita_location,
        cases: 41_035,
        deaths: 3_405,
        recoveries: 4_440,
        active_cases: 33_190
      )

      insert(:covid_case,
        datetime: ~U[2020-03-20 23:01:46.000000Z],
        location:
          insert(:covid_location,
            country_code: "USA",
            country: "United States of America",
            source_location: %BillBored.Geo.Point{lat: 37.0902405, long: -95.7128906}
          ),
        cases: 14_250,
        deaths: 205,
        recoveries: 121,
        active_cases: 13_924
      )

      covid_info = %{
        key: "covid_info",
        value: %BillBored.KVEntries.CovidInfo.Value{
          enabled: true,
          info: "<h1>Useful COVID info</h1>"
        },
        updated_at: DateTime.utc_now()
      }

      Repo.insert_all(BillBored.KVEntries.CovidInfo, [covid_info],
        conflict_target: [:key],
        on_conflict: {:replace, [:value]}
      )

      %{ita_location: ita_location}
    end

    test "returns cases data", %{conn: conn} do
      assert %{
               "worldwide" => worldwide,
               "info" => info,
               "updated_at" => "2020-03-20T00:00:00.000000Z",
               "cases" => cases
             } =
               conn
               |> put_req_header("authorization", "Bearer #{insert(:auth_token).key}")
               |> get(Routes.covid_path(conn, :list_by_country))
               |> doc()
               |> json_response(200)

      assert [
               %{
                 "active_cases" => 6731,
                 "cases" => 81250,
                 "country" => "China",
                 "deaths" => 3253,
                 "location" => %{
                   "coordinates" => [39.913818, 116.363625],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "population" => 0,
                 "recoveries" => 71266,
                 "region" => "",
                 "source_url" => ""
               },
               %{
                 "active_cases" => 33190,
                 "cases" => 41035,
                 "country" => "Italy",
                 "deaths" => 3405,
                 "location" => %{
                   "coordinates" => [41.902782, 12.496366],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "population" => 0,
                 "recoveries" => 4440,
                 "region" => "",
                 "source_url" => ""
               },
               %{
                 "active_cases" => 13924,
                 "cases" => 14250,
                 "country" => "United States of America",
                 "deaths" => 205,
                 "location" => %{
                   "coordinates" => [37.0902405, -95.7128906],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "population" => 0,
                 "recoveries" => 121,
                 "region" => "",
                 "source_url" => ""
               }
             ] == cases

      assert %{
               "active_cases" => 53845,
               "cases" => 136_535,
               "country" => "",
               "deaths" => 6863,
               "location" => %{
                 "coordinates" => [0.0, 0.0],
                 "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                 "type" => "Point"
               },
               "population" => 0,
               "recoveries" => 75827,
               "region" => "",
               "source_url" => ""
             } == worldwide

      assert %{
               "enabled" => true,
               "info" => "<h1>Useful COVID info</h1>"
             } == info
    end

    test "returns only data for most recent day", %{conn: conn, ita_location: ita_location} do
      insert(:covid_case,
        datetime: ~U[2020-03-21 10:15:00.000000Z],
        location: ita_location,
        cases: 41_037,
        deaths: 3_405,
        recoveries: 4_450,
        active_cases: 33_180
      )

      assert %{
               "updated_at" => "2020-03-21T00:00:00.000000Z",
               "cases" => cases
             } =
               conn
               |> put_req_header("authorization", "Bearer #{insert(:auth_token).key}")
               |> get(Routes.covid_path(conn, :list_by_country))
               |> json_response(200)

      assert [
               %{
                 "active_cases" => 33180,
                 "cases" => 41037,
                 "country" => "Italy",
                 "deaths" => 3405,
                 "location" => %{
                   "coordinates" => [41.902782, 12.496366],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "population" => 0,
                 "recoveries" => 4450,
                 "region" => "",
                 "source_url" => ""
               }
             ] == cases
    end
  end

  describe "list_by_region/2" do
    setup do
      insert(:covid_case,
        datetime: ~U[2020-03-20 23:01:46.000000Z],
        location:
          insert(:covid_location,
            country_code: "USA",
            scope: "county",
            region: "IL, Brown County",
            location: %BillBored.Geo.Point{lat: 39.971889000000004, long: -90.71462349999999}
          ),
        cases: 0,
        deaths: 0,
        recoveries: 0,
        active_cases: 0
      )

      insert(:covid_case,
        datetime: ~U[2020-03-20 23:01:46.000000Z],
        location:
          insert(:covid_location,
            country_code: "USA",
            scope: "county",
            region: "IL, Champaign County",
            location: %BillBored.Geo.Point{lat: 40.139787999999996, long: -88.19621000000001}
          ),
        cases: 1,
        deaths: 0,
        recoveries: 0,
        active_cases: 1
      )

      insert(:covid_case,
        datetime: ~U[2020-03-20 23:01:46.000000Z],
        location:
          insert(:covid_location,
            country_code: "USA",
            scope: "state",
            region: "NJ",
            location: %BillBored.Geo.Point{lat: 12.104873978005386, long: 15.06717673331957}
          ),
        cases: 250,
        deaths: 0,
        recoveries: 0,
        active_cases: 250
      )

      :ok
    end

    test "returns cases data", %{conn: conn} do
      assert %{
               "updated_at" => "2020-03-20T00:00:00.000000Z",
               "cases" => cases
             } =
               conn
               |> put_req_header("authorization", "Bearer #{insert(:auth_token).key}")
               |> get(Routes.covid_path(conn, :list_by_region))
               |> doc()
               |> json_response(200)

      assert [
               %{
                 "active_cases" => 0,
                 "cases" => 0,
                 "country" => "USA",
                 "deaths" => 0,
                 "location" => %{
                   "coordinates" => [39.971889000000004, -90.71462349999999],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "population" => 0,
                 "recoveries" => 0,
                 "region" => "IL, Brown County",
                 "source_url" => ""
               },
               %{
                 "active_cases" => 1,
                 "cases" => 1,
                 "country" => "USA",
                 "deaths" => 0,
                 "location" => %{
                   "coordinates" => [40.139787999999996, -88.19621000000001],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "population" => 0,
                 "recoveries" => 0,
                 "region" => "IL, Champaign County",
                 "source_url" => ""
               },
               %{
                 "active_cases" => 250,
                 "cases" => 250,
                 "country" => "USA",
                 "deaths" => 0,
                 "location" => %{
                   "coordinates" => [12.104873978005386, 15.06717673331957],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "population" => 0,
                 "recoveries" => 0,
                 "region" => "NJ",
                 "source_url" => ""
               }
             ] ==
               cases
    end
  end
end
