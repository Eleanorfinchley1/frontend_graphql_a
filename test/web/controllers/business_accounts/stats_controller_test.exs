defmodule Web.BusinessAccounts.StatsControllerTest do
  use Web.ConnCase, async: true

  import BillBored.ServiceRegistry, only: [replace: 2]

  defmodule Stubs.Clickhouse.PostViews do
    def get_post_views("1", _accuracy_radius) do
      {:error, :some_error}
    end

    def get_post_views("2", _) do
      {:ok,
       %{
         accuracy_radius: 0.001,
         precision: 12,
         views: [
           %{
             count: 1,
             location: %BillBored.Geo.Point{lat: 37.6155599, long: 55.75221998}
           },
           %{
             count: 2,
             location: %BillBored.Geo.Point{lat: -73.93524187, long: 40.73060998}
           }
         ]
       }}
    end

    def get_post_stats("1") do
      {:error, :some_error}
    end

    def get_post_stats("2") do
      {:ok,
       %{
         total_views: 3,
         unique_views: 3,
         views_by_city: [
           %{"city" => "New York", "country" => "USA", "unique_views" => 2},
           %{"city" => "Moscow", "country" => "Russia", "unique_views" => 1}
         ],
         views_by_sex: [
           %{"sex" => "F", "unique_views" => 1},
           %{"sex" => "M", "unique_views" => 2}
         ]
       }}
    end

    def get_business_stats(_) do
      {:ok,
       %{
         total_views: 3,
         unique_views: 3,
         viewed_posts: 1,
         views_by_city: [
           %{"city" => "New York", "country" => "USA", "unique_views" => 2},
           %{"city" => "Moscow", "country" => "Russia", "unique_views" => 1}
         ],
         views_by_sex: [
           %{"sex" => "F", "unique_views" => 1},
           %{"sex" => "M", "unique_views" => 2}
         ]
       }}
    end
  end

  defmodule Stubs.Clickhouse.PostViews.Error do
    def get_business_stats(_) do
      {:error, :some_error}
    end
  end

  setup do
    replace(BillBored.Clickhouse.PostViews, Stubs.Clickhouse.PostViews)

    business_account = insert(:business_account)
    member = insert(:user)
    insert(:user_membership, business_account: business_account, member: member, role: "member")

    %{business_account: business_account, member: member}
  end

  describe "GET post_views" do
    test "returns post views stats", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      assert %{
               "views" => [
                 %{
                   "count" => 1,
                   "location" => %{
                     "coordinates" => [37.6155599, 55.75221998],
                     "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                     "type" => "Point"
                   }
                 },
                 %{
                   "count" => 2,
                   "location" => %{
                     "coordinates" => [-73.93524187, 40.73060998],
                     "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                     "type" => "Point"
                   }
                 }
               ]
             } ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_stats_path(
                   conn,
                   :post_views,
                   business_account.id,
                   2
                 )
               )
               |> doc()
               |> json_response(200)
    end

    test "returns 403 for non member", %{
      conn: conn,
      business_account: business_account
    } do
      conn
      |> authenticate()
      |> get(
        Routes.business_accounts_stats_path(
          conn,
          :post_views,
          business_account.id,
          1
        )
      )
      |> doc()
      |> response(403)
    end

    test "returns error when can't fetch stats", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      assert %{"error" => "some_error", "reason" => "some_error", "success" => false} ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_stats_path(
                   conn,
                   :post_views,
                   business_account.id,
                   1
                 )
               )
               |> doc()
               |> json_response(422)
    end
  end

  describe "GET post_stats" do
    test "returns post stats", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      assert %{
               "total_views" => 3,
               "unique_views" => 3,
               "views_by_city" => [
                 %{"city" => "New York", "country" => "USA", "unique_views" => 2},
                 %{"city" => "Moscow", "country" => "Russia", "unique_views" => 1}
               ],
               "views_by_sex" => [
                 %{"sex" => "F", "unique_views" => 1},
                 %{"sex" => "M", "unique_views" => 2}
               ]
             } ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_stats_path(
                   conn,
                   :post_stats,
                   business_account.id,
                   2
                 )
               )
               |> doc()
               |> json_response(200)
    end

    test "returns 403 for non member", %{
      conn: conn,
      business_account: business_account
    } do
      conn
      |> authenticate()
      |> get(
        Routes.business_accounts_stats_path(
          conn,
          :post_stats,
          business_account.id,
          1
        )
      )
      |> doc()
      |> response(403)
    end

    test "returns error when can't fetch stats", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      assert %{"error" => "some_error", "reason" => "some_error", "success" => false} ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_stats_path(
                   conn,
                   :post_stats,
                   business_account.id,
                   1
                 )
               )
               |> doc()
               |> json_response(422)
    end
  end

  describe "GET stats" do
    test "returns business stats", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      assert %{
               "viewed_posts" => 1,
               "total_views" => 3,
               "unique_views" => 3,
               "views_by_city" => [
                 %{"city" => "New York", "country" => "USA", "unique_views" => 2},
                 %{"city" => "Moscow", "country" => "Russia", "unique_views" => 1}
               ],
               "views_by_sex" => [
                 %{"sex" => "F", "unique_views" => 1},
                 %{"sex" => "M", "unique_views" => 2}
               ]
             } ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_stats_path(
                   conn,
                   :stats,
                   business_account.id
                 )
               )
               |> doc()
               |> json_response(200)
    end

    test "returns 403 for non member", %{
      conn: conn,
      business_account: business_account
    } do
      conn
      |> authenticate()
      |> get(
        Routes.business_accounts_stats_path(
          conn,
          :stats,
          business_account.id
        )
      )
      |> doc()
      |> response(403)
    end

    test "returns error when can't fetch stats", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      replace(BillBored.Clickhouse.PostViews, Stubs.Clickhouse.PostViews.Error)

      assert %{"error" => "some_error", "reason" => "some_error", "success" => false} ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_stats_path(
                   conn,
                   :stats,
                   business_account.id
                 )
               )
               |> doc()
               |> json_response(422)
    end
  end
end
