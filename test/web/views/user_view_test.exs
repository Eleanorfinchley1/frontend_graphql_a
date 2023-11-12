defmodule Web.UserViewTest do
  use Web.ConnCase, async: true

  import BillBored.Factory

  describe "user view" do
    setup [:create_users]

    @tag :skip
    test "template \"index.json\" renders", %{conn: conn, tokens: tokens} do
      users = for t <- tokens, do: t.user

      for i <- 1..75 do
        insert(:user_friendship, users: [hd(users), Enum.at(users, i)])
      end

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.user_path(conn, :index_friends))
        |> response(200)
        |> Jason.decode!()

      refute resp["prev"]
      assert length(resp["entries"]) == 10
      assert resp["next"] && String.contains?(resp["next"], "page=2")
      assert resp["page_number"] == 1
      assert resp["total_entries"] == 75
      assert resp["total_pages"] == 8

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.user_path(conn, :index_friends, page: 2))
        |> response(200)
        |> Jason.decode!()

      assert length(resp["entries"]) == 10
      assert resp["prev"] && String.contains?(resp["prev"], "page=1")
      assert resp["next"] && String.contains?(resp["next"], "page=3")
      assert resp["page_number"] == 2
      assert resp["total_entries"] == 75
      assert resp["total_pages"] == 8

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.user_path(conn, :index_friends, page: 8))
        |> response(200)
        |> Jason.decode!()

      assert length(resp["entries"]) == 5
      assert resp["prev"] && String.contains?(resp["prev"], "page=7")
      refute resp["next"]
      assert resp["page_number"] == 8

      id = hd(users).id

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.user_path(conn, :index_friends_of_user, id, page: 4))
        |> response(200)
        |> Jason.decode!()

      prev = resp["prev"]
      next = resp["next"]

      assert length(resp["entries"]) == 10
      assert prev && String.contains?(prev, "page=3") && String.contains?(prev, "#{id}")
      assert next && String.contains?(next, "page=5") && String.contains?(next, "#{id}")
      assert resp["page_number"] == 4
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..100, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
