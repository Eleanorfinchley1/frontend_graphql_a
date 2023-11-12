defmodule Web.CommentControllerTest do
  use Web.ConnCase, async: true

  import BillBored.Factory

  describe "post comments" do
    setup [:create_users]

    test "returned paginated", %{conn: conn, tokens: tokens} do
      [token | _] = tokens

      post = insert(:post, author: token.user)

      for _ <- 1..75, do: insert(:post_comment, post: post)

      resp =
        conn
        |> authenticate(token)
        |> get(Routes.post_comment_path(conn, :index, post.id))
        |> json_response(200)

      assert length(resp["entries"]) == 10
      assert resp["next"] && String.contains?(resp["next"], "page=2")
      assert resp["page_number"] == 1
      assert resp["total_entries"] == 75
      assert resp["total_pages"] == 8
    end
  end

  describe "post comment" do
    setup [:create_users]

    test "can be created", %{conn: conn, tokens: tokens} do
      [token1, token2 | _] = tokens

      post = insert(:post)

      params = %{
        "post_id" => post.id,
        "body" => "COMMENT BODY",
        "interests" => ["job", "money"]
      }

      comment_json =
        conn
        |> authenticate(token1)
        |> post(Routes.post_comment_path(conn, :create, post.id), params)
        |> json_response(200)

      # shows in indexes:

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :index, post.id))
        |> json_response(200)

      assert length(resp["entries"]) == 1

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :index_top, post.id))
        |> json_response(200)

      assert length(resp["entries"]) == 1

      # can be shown separately:

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :show, comment_json["id"]))
        |> json_response(200)

      assert resp["id"] == comment_json["id"]
      assert resp["author"]
      assert resp["media_file_keys"]
      assert resp["number_of_replies"] == 0
      assert resp["children"] == []
      refute resp["parent_id"]
      assert resp["blocked?"] == false
    end

    test "can be updated", %{conn: conn, tokens: tokens} do
      [token1, token2 | _] = tokens

      comment = insert(:post_comment, author: token1.user)

      params = %{
        "body" => "NEW BODY",
        "disabled?" => true,
        "interests" => ["job", "money"]
      }

      conn
      |> authenticate(token2)
      |> put(Routes.post_comment_path(conn, :update, comment.id), params)
      |> response(403)

      comment_json =
        conn
        |> authenticate(token1)
        |> put(Routes.post_comment_path(conn, :update, comment.id), params)
        |> json_response(200)

      assert comment_json["disabled?"] == true
      assert comment_json["body"] == "NEW BODY"
      assert comment_json["interests"] == ["job", "money"]
    end

    test "can be have childs", %{conn: conn, tokens: tokens} do
      [token1, token2 | _] = tokens

      post = insert(:post)

      comment1 = insert(:post_comment, author: token1.user, post: post)
      comment2 = insert(:post_comment, author: token2.user, post: post)

      params = %{"body" => "COMMENT BODY"}

      comment_json =
        conn
        |> authenticate(token1)
        |> post(Routes.post_comment_path(conn, :create_child, comment1.id), params)
        |> json_response(200)

      conn
      |> authenticate(token1)
      |> post(Routes.post_comment_path(conn, :create_child, comment2.id), params)
      |> response(200)

      assert comment_json["parent_id"] == comment1.id
      assert comment_json["post_id"] == comment1.post_id

      conn
      |> authenticate(token1)
      |> post(Routes.post_comment_path(conn, :create_child, comment_json["id"]), params)
      |> response(200)

      conn
      |> authenticate(token1)
      |> post(Routes.post_comment_path(conn, :create_child, comment_json["id"]), params)
      |> response(200)

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :index_top, post.id))
        |> json_response(200)

      assert length(resp["entries"]) == 2

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :index_childs, comment2.id))
        |> json_response(200)

      assert length(resp["entries"]) == 1

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :index_childs, comment_json["id"]))
        |> json_response(200)

      assert length(resp["entries"]) == 2

      #

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :index, post.id))
        |> json_response(200)

      assert length(resp["entries"]) == 2
    end

    test "delete also removes child comments", %{conn: conn, tokens: tokens} do
      [token | _] = tokens

      post = insert(:post, author: token.user)

      comment = insert(:post_comment, author: token.user, post: post)

      comment1 = insert(:post_comment, author: token.user, parent: comment)
      comment2 = insert(:post_comment, author: token.user, parent: comment)

      resp =
        conn
        |> authenticate(token)
        |> get(Routes.post_comment_path(conn, :index, post.id))
        |> json_response(200)

      [comment_json] = resp["entries"]

      assert length(comment_json["children"]) == 2

      conn
      |> authenticate(token)
      |> delete(Routes.post_comment_path(conn, :delete, comment.id))
      |> response(204)

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(token)
        |> get(Routes.post_comment_path(conn, :show, comment.id))
      end

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(token)
        |> get(Routes.post_comment_path(conn, :show, comment1.id))
      end

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(token)
        |> get(Routes.post_comment_path(conn, :show, comment2.id))
      end
    end

    test "can be deleted", %{conn: conn, tokens: tokens} do
      [token1, token2 | _] = tokens

      comment = insert(:post_comment, author: token1.user)

      conn
      |> authenticate(token2)
      |> delete(Routes.post_comment_path(conn, :delete, comment.id))
      |> response(403)

      conn
      |> authenticate(token1)
      |> delete(Routes.post_comment_path(conn, :delete, comment.id))
      |> response(204)

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(token1)
        |> delete(Routes.post_comment_path(conn, :delete, comment.id))
      end

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(token2)
        |> delete(Routes.post_comment_path(conn, :delete, comment.id))
      end
    end
  end

  describe "upvote/downvote/unvote" do
    setup [:create_users]

    test "are working as expected", %{conn: conn, tokens: tokens} do
      [author, token2, token3 | _] = tokens

      _post = insert(:post, author: author.user)
      comment = insert(:post_comment, author: author.user)

      vote = fn token, action ->
        conn
        |> authenticate(token)
        |> post(Routes.post_comment_path(conn, :vote, comment.id, %{"action" => action}))
        |> response(204)

        conn
        |> authenticate(token)
        |> get(Routes.post_comment_path(conn, :show, comment.id))
        |> json_response(200)
      end

      make_twice = fn token, action ->
        vote.(token, action)

        # and again:
        vote.(token, action)
      end

      # upvote

      resp = make_twice.(token2, "upvote")
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 0

      resp =
        conn
        |> authenticate(token3)
        |> get(Routes.post_comment_path(conn, :show, comment.id))
        |> json_response(200)

      assert resp["user_upvoted?"] == false
      assert resp["user_downvoted?"] == false

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :show, comment.id))
        |> json_response(200)

      assert resp["user_upvoted?"] == true
      assert resp["user_downvoted?"] == false

      resp = make_twice.(token2, "downvote")
      assert resp["upvotes_count"] == 0
      assert resp["downvotes_count"] == 1

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.post_comment_path(conn, :show, comment.id))
        |> json_response(200)

      assert resp["user_upvoted?"] == false
      assert resp["user_downvoted?"] == true

      # downvote

      resp = make_twice.(token3, "upvote")
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 1

      resp = make_twice.(token3, "downvote")
      assert resp["upvotes_count"] == 0
      assert resp["downvotes_count"] == 2

      # making upvote for the author

      resp = vote.(author, "upvote")
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 2

      # unvote

      unvote = &vote.(&1, "unvote")

      resp = unvote.(token2)
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 1

      resp = unvote.(token3)
      assert resp["upvotes_count"] == 1
      assert resp["downvotes_count"] == 0

      resp = unvote.(author)
      assert resp["upvotes_count"] == 0
      assert resp["downvotes_count"] == 0
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..10, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
