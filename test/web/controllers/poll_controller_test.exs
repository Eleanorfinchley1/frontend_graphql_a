defmodule Web.PollControllerTest do
  use Web.ConnCase, async: true
  import BillBored.Factory

  describe "poll" do
    setup [:create_users]

    @tag :skip
    test "can be added to post", %{conn: conn, tokens: [author, other | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "question" => "Question?",
        "items" => ["yes", "no"]
      }

      conn
      |> authenticate(other.key)
      |> post(Routes.poll_path(conn, :create, post.id), params)
      |> response(403)

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.poll_path(conn, :create, post.id), params)
        |> json_response(200)

      poll = resp["result"]
      assert resp["success"] && resp["result"]
      assert length(poll["items"]) == 2

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      assert resp["question"] == "Question?"
      assert length(resp["items"]) == 2

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.post_path(conn, :show, post.id))
        |> json_response(200)

      assert [single_poll] = resp["polls"]
      assert single_poll["id"] == poll["id"]

      # with extended items
      params = %{
        "question" => "Question?",
        "items" => [
          %{
            media_file_keys: [],
            title: "item1"
          },
          %{
            media_file_keys: [],
            title: "item2"
          }
        ]
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.poll_path(conn, :create, post.id), params)
        |> json_response(200)

      poll = resp["result"]
      assert resp["success"] && resp["result"]
      assert length(poll["items"]) == 2

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      assert resp["question"] == "Question?"
      assert length(resp["items"]) == 2

      # add item to the poll

      item3 = %{
        media_file_keys: [],
        title: "item3"
      }

      conn
      |> authenticate(other.key)
      |> post(Routes.poll_path(conn, :add_item, poll["id"]), item3)
      |> response(403)

      _resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      conn
      |> authenticate(author.key)
      |> post(Routes.poll_path(conn, :add_item, poll["id"]), item3)
      |> response(204)

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      assert resp["question"] == "Question?"
      assert length(resp["items"]) == 3
    end

    test "can be updated", %{conn: conn, tokens: [author | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "question" => "Question?",
        "items" => ["yes", "no"]
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.poll_path(conn, :create, post.id), params)
        |> json_response(200)

      poll = resp["result"]

      new_params = %{
        "question" => "Жить будешь?",
        "items" => ["нет", "да", "возможно"]
      }

      resp =
        conn
        |> authenticate(author.key)
        |> put(Routes.poll_path(conn, :update, poll["id"]), new_params)
        |> json_response(200)

      poll = resp["result"]

      assert poll["question"] == new_params["question"]
      assert length(poll["items"]) == 3
    end

    test "can be deleted", %{conn: conn, tokens: [author, other | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "question" => "Question?",
        "items" => ["yes", "no"]
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.poll_path(conn, :create, post.id), params)
        |> json_response(200)

      poll = resp["result"]
      [item1, item2] = poll["items"]

      # delete item1:

      conn
      |> authenticate(other.key)
      |> delete(Routes.poll_path(conn, :delete_item, item1["id"]))
      |> response(403)

      conn
      |> authenticate(author.key)
      |> delete(Routes.poll_path(conn, :delete_item, item1["id"]))
      |> response(204)

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(author.key)
        |> delete(Routes.poll_path(conn, :delete_item, item1["id"]))
      end

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      assert [^item2] = resp["items"]

      # delete poll
      conn
      |> authenticate(other.key)
      |> delete(Routes.poll_path(conn, :delete, poll["id"]))
      |> response(403)

      conn
      |> authenticate(author.key)
      |> delete(Routes.poll_path(conn, :delete, poll["id"]))
      |> response(204)

      assert_raise Ecto.NoResultsError, fn ->
        conn
        |> authenticate(other.key)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
      end

      # no associations for post anymore

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.post_path(conn, :show, post.id))
        |> json_response(200)

      assert [] = resp["polls"]
    end

    test "can be voted and unvoted", %{conn: conn, tokens: tokens} do
      [author, token2, token3 | _] = tokens

      post = insert(:post, author: author.user)

      params = %{
        "question" => "Question?",
        "items" => ["yes", "no"]
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.poll_path(conn, :create, post.id), params)
        |> json_response(200)

      poll = resp["result"]

      [item1, item2] = poll["items"]

      refute item1["user_voted?"]
      refute item2["user_voted?"]
      assert item1["votes_count"] == 0
      assert item2["votes_count"] == 0

      vote = fn token, item ->
        conn
        |> authenticate(token)
        |> put(Routes.poll_path(conn, :vote, item["id"]))
        |> response(204)

        conn
        |> authenticate(token)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)
      end

      make_twice = fn token, item ->
        vote.(token, item)
        vote.(token, item)
      end

      # vote

      resp = make_twice.(token2, item1)
      [i1, i2] = resp["items"]

      assert i1["votes_count"] == 1
      assert i2["votes_count"] == 0
      assert i1["user_voted?"] == true
      assert i2["user_voted?"] == false

      resp =
        conn
        |> authenticate(token3)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      [i1, i2] = resp["items"]
      assert i1["votes_count"] == 1
      assert i2["votes_count"] == 0
      assert i1["user_voted?"] == false
      assert i2["user_voted?"] == false

      # token2.user changes his decision:

      resp = make_twice.(token2, item2)
      [i1, i2] = resp["items"]

      assert i1["votes_count"] == 0
      assert i2["votes_count"] == 1
      assert i1["user_voted?"] == false
      assert i2["user_voted?"] == true

      resp =
        conn
        |> authenticate(token3)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      [i1, i2] = resp["items"]
      assert i1["votes_count"] == 0
      assert i2["votes_count"] == 1
      assert i1["user_voted?"] == false
      assert i2["user_voted?"] == false

      # now token3.user votes for item2

      resp = make_twice.(token3, item2)
      [i1, i2] = resp["items"]

      assert i1["votes_count"] == 0
      assert i2["votes_count"] == 2
      assert i1["user_voted?"] == false
      assert i2["user_voted?"] == true

      resp =
        conn
        |> authenticate(token2)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)

      [i1, i2] = resp["items"]
      assert i1["votes_count"] == 0
      assert i2["votes_count"] == 2
      assert i1["user_voted?"] == false
      assert i2["user_voted?"] == true

      # unvote

      unvote = fn token ->
        conn
        |> authenticate(token)
        |> delete(Routes.poll_path(conn, :unvote_all, poll["id"]))
        |> response(204)

        conn
        |> authenticate(token)
        |> get(Routes.poll_path(conn, :show, poll["id"]))
        |> json_response(200)
      end

      resp = unvote.(token2)

      [i1, i2] = resp["items"]
      assert i1["votes_count"] == 0
      assert i1["user_voted?"] == false
      assert i2["votes_count"] == 1
      assert i2["user_voted?"] == false

      resp = unvote.(token3)

      [i1, i2] = resp["items"]
      assert i1["votes_count"] == 0
      assert i1["user_voted?"] == false
      assert i2["votes_count"] == 0
      assert i2["user_voted?"] == false
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..10, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
