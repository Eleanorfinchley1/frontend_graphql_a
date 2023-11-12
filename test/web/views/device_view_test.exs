defmodule Web.DeviceViewTest do
  use Web.ConnCase, async: true

  import BillBored.Factory

  describe "device view" do
    setup [:create_users]

    test "template \"index.json\" renders", %{conn: conn, tokens: tokens} do
      [owner | _] = for t <- tokens, do: t.user

      for _ <- 1..75, do: insert(:user_device, user: owner)

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.device_path(conn, :index))
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
        |> get(Routes.device_path(conn, :index, page: 2))
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
        |> get(Routes.device_path(conn, :index, page: 8))
        |> response(200)
        |> Jason.decode!()

      assert length(resp["entries"]) == 5
      assert resp["prev"] && String.contains?(resp["prev"], "page=7")
      refute resp["next"]
      assert resp["page_number"] == 8
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..100, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
