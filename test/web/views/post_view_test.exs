defmodule Web.PostViewTest do
  use Web.ConnCase, async: true
  import BillBored.Factory

  describe "post view" do
    setup [:create_users]

    test "template \"index.json\" renders", %{conn: conn, tokens: tokens} do
      [author | _] = _users = for t <- tokens, do: t.user

      for _i <- 1..75, do: insert(:post, author: author)

      resp =
        conn
        |> authenticate(hd(tokens))
        |> get(Routes.post_path(conn, :index, author.id))
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
        |> get(Routes.post_path(conn, :index, author.id, page: 2))
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
        |> get(Routes.post_path(conn, :index, author.id, page: 8))
        |> response(200)
        |> Jason.decode!()

      assert length(resp["entries"]) == 5
      assert resp["prev"] && String.contains?(resp["prev"], "page=7")
      refute resp["next"]
      assert resp["page_number"] == 8
    end
  end

  describe "render/1 show.json" do
    test "renders post without event provider" do
      %{body: body, title: title, type: type} =
        post =
        insert(:post, event_provider: nil)
        |> Repo.preload([:media_files, :interests, :place, :polls, :events])

      assert %{
               type: ^type,
               body: ^body,
               title: ^title,
               event_provider: ""
             } = Web.PostView.render("show.json", %{post: post})
    end

    test "renders post with event provider" do
      %{body: body, title: title, type: type} =
        post =
        insert(:post, event_provider: "allevents", provider_id: "allevents-id-1111")
        |> Repo.preload([:media_files, :interests, :place, :polls, :events])

      assert %{
               type: ^type,
               body: ^body,
               title: ^title,
               event_provider: "allevents"
             } = Web.PostView.render("show.json", %{post: post})
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..100, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
