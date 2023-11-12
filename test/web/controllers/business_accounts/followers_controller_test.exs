defmodule Web.BusinessAccounts.FollowersControllerTest do
  use Web.ConnCase, async: true

  setup do
    business_account = insert(:business_account)
    member = insert(:user)
    insert(:user_membership, business_account: business_account, member: member, role: "member")

    %{business_account: business_account, member: member}
  end

  describe "GET history" do
    test "returns business followers history", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      insert(:user_following, to: business_account, inserted_at: ~U[2020-06-06 12:00:00Z])
      insert(:user_following, to: business_account, inserted_at: ~U[2021-01-25 23:59:59Z])
      insert(:user_following, to: business_account, inserted_at: ~U[2000-01-01 00:00:00Z])
      insert(:user_following, to: business_account, inserted_at: ~U[2020-06-06 15:00:00Z])


      assert %{
               "history" => [
                 %{"count" => 1, "date" => "2000-01-01"},
                 %{"count" => 2, "date" => "2020-06-06"},
                 %{"count" => 1, "date" => "2021-01-25"}
               ]
             } ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_followers_path(
                   conn,
                   :history,
                   business_account.id
                 )
               )
               |> doc()
               |> json_response(200)
    end

    test "returns empty array when business has no followers", %{
      conn: conn,
      member: member,
      business_account: business_account
    } do
      assert %{
               "history" => []
             } ==
               conn
               |> authenticate(member)
               |> get(
                 Routes.business_accounts_followers_path(
                   conn,
                   :history,
                   business_account.id
                 )
               )
               |> json_response(200)
    end

    test "returns 403 for not a member", %{
      conn: conn,
      business_account: business_account
    } do
      conn
      |> authenticate()
      |> get(
        Routes.business_accounts_followers_path(
          conn,
          :history,
          business_account.id
        )
      )
      |> response(403)
    end
  end
end
