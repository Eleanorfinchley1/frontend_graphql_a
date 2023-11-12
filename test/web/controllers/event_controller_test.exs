defmodule Web.EventControllerTest do
  use Web.ConnCase, async: true
  import BillBored.Factory

  describe "event" do
    setup [:create_users]

    @tag :skip
    test "can be added to post", %{conn: conn, tokens: [author, other | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "buy_ticket_link" => "http://google.com",
        "child_friendly" => false,
        "currency" => "USD",
        "date" => "2019-07-16T01:51:09.427780Z",
        "location" => [
          30.7008,
          76.7885
        ],
        "media_file_keys" => [],
        "price" => 10,
        "title" => "EVENT"
      }

      conn
      |> authenticate(other.key)
      |> post(Routes.event_path(conn, :create, post.id), params)
      |> response(403)

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.event_path(conn, :create, post.id), params)
        |> response(200)
        |> Jason.decode!()

      event = resp["result"]
      assert resp["success"] && resp["result"]

      for field <- ["child_friendly", "buy_ticket_link", "currency", "date", "price", "title"] do
        assert event[field] == params[field]
      end

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.event_path(conn, :show, event["id"]))
        |> response(200)
        |> Jason.decode!()

      refute resp["success"] || resp["result"]

      for field <- ["child_friendly", "buy_ticket_link", "currency", "date", "price", "title"] do
        assert resp[field] == params[field]
      end

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.post_path(conn, :show, post.id))
        |> response(200)
        |> Jason.decode!()

      assert [single_event] = resp["events"]
      assert single_event["id"] == event["id"]
    end

    @tag :skip
    test "can be updated", %{conn: conn, tokens: [author | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "buy_ticket_link" => "http://google.com",
        "child_friendly" => false,
        "currency" => "USD",
        "date" => "2019-07-16T01:51:09.427780Z",
        "location" => [
          30.7008,
          76.7885
        ],
        "media_file_keys" => [],
        "price" => 10,
        "title" => "EVENT"
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.event_path(conn, :create, post.id), params)
        |> response(200)
        |> Jason.decode!()

      new_params = %{
        params
        | "buy_ticket_link" => "http://yandex.ru",
          "child_friendly" => false,
          "currency" => "RUB",
          "date" => "2019-08-16T01:51:09.427780Z",
          "price" => 1_000_000.4,
          "title" => "EVENT_UPD"
      }

      event = resp["result"]

      resp =
        conn
        |> authenticate(author.key)
        |> put(Routes.event_path(conn, :update, event["id"]), new_params)
        |> response(200)
        |> Jason.decode!()

      event = resp["result"]

      for field <- ["child_friendly", "buy_ticket_link", "currency", "date", "price", "title"] do
        assert event[field] == new_params[field]
      end
    end

    @tag :skip
    test "can be deleted", %{conn: conn, tokens: [author, other | _]} do
      post = insert(:post, author: author.user)

      params = %{
        "buy_ticket_link" => "http://google.com",
        "child_friendly" => false,
        "currency" => "USD",
        "date" => "2019-07-16T01:51:09.427780Z",
        "location" => [
          30.7008,
          76.7885
        ],
        "media_file_keys" => [],
        "price" => 10,
        "title" => "EVENT"
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.event_path(conn, :create, post.id), params)
        |> response(200)
        |> Jason.decode!()

      event = resp["result"]

      _resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.event_path(conn, :show, event["id"]))
        |> response(200)
        |> Jason.decode!()

      # delete event
      conn
      |> authenticate(other.key)
      |> delete(Routes.event_path(conn, :delete, event["id"]))
      |> response(403)

      conn
      |> authenticate(author.key)
      |> delete(Routes.event_path(conn, :delete, event["id"]))
      |> response(204)

      conn
      |> authenticate(other.key)
      |> get(Routes.event_path(conn, :show, event["id"]))
      |> response(404)

      # no associations for post anymore

      resp =
        conn
        |> authenticate(other.key)
        |> get(Routes.post_path(conn, :show, post.id))
        |> response(200)
        |> Jason.decode!()

      assert [] = resp["events"]
    end

    @tag :skip
    test "can be attended", %{conn: conn, tokens: tokens} do
      [author, token2, token3 | _] = tokens

      post = insert(:post, author: author.user)

      params = %{
        "buy_ticket_link" => "http://google.com",
        "child_friendly" => false,
        "currency" => "USD",
        "date" => "2019-07-16T01:51:09.427780Z",
        "location" => [
          30.7008,
          76.7885
        ],
        "media_file_keys" => [],
        "price" => 10,
        "title" => "EVENT"
      }

      resp =
        conn
        |> authenticate(author.key)
        |> post(Routes.event_path(conn, :create, post.id), params)
        |> response(200)
        |> Jason.decode!()

      event = resp["result"]

      refute event["user_status"]
      assert event["accepted_count"] == 0
      assert event["invited_count"] == 0
      assert event["refused_count"] == 0
      assert event["doubts_count"] == 0
      assert event["missed_count"] == 0
      assert event["presented_count"] == 0

      invite = fn user ->
        conn
        |> authenticate(author)
        |> put(Routes.event_path(conn, :invite, event["id"], user_id: user.id))
        |> response(204)

        conn
        |> authenticate(author)
        |> get(Routes.event_path(conn, :show, event["id"]))
        |> response(200)
        |> Jason.decode!()
      end

      attend = fn token, status ->
        conn
        |> authenticate(token)
        |> put(Routes.event_path(conn, :set_status, event["id"], status: status))
        |> response(204)

        conn
        |> authenticate(token)
        |> get(Routes.event_path(conn, :show, event["id"]))
        |> response(200)
        |> Jason.decode!()
      end

      make_twice = fn user ->
        invite.(user)
        invite.(user)
      end

      # invite

      conn
      |> authenticate(token2)
      |> put(Routes.event_path(conn, :invite, event["id"], user_id: token3.user.id))
      |> response(403)

      conn
      |> authenticate(token3)
      |> put(Routes.event_path(conn, :invite, event["id"], user_id: token3.user.id))
      |> response(403)

      # inviting token2.user

      event = make_twice.(token2.user)

      refute event["user_status"]
      assert event["invited_count"] == 1
      assert event["refused_count"] == 0
      assert event["doubts_count"] == 0
      assert event["missed_count"] == 0
      assert event["presented_count"] == 0

      event =
        conn
        |> authenticate(token2)
        |> get(Routes.event_path(conn, :show, event["id"]))
        |> response(200)
        |> Jason.decode!()

      assert event["user_status"] == "invited"

      # inviting token3.user

      event = make_twice.(token3.user)

      assert event["accepted_count"] == 0
      assert event["invited_count"] == 2
      assert event["refused_count"] == 0
      assert event["doubts_count"] == 0
      assert event["missed_count"] == 0
      assert event["presented_count"] == 0

      event =
        conn
        |> authenticate(token3)
        |> get(Routes.event_path(conn, :show, event["id"]))
        |> response(200)
        |> Jason.decode!()

      assert event["user_status"] == "invited"

      # token2.user accepted:

      event = attend.(token2, "accepted")
      assert event["user_status"] == "accepted"

      assert event["accepted_count"] == 1
      assert event["invited_count"] == 1
      assert event["refused_count"] == 0
      assert event["doubts_count"] == 0
      assert event["missed_count"] == 0
      assert event["presented_count"] == 0

      event = attend.(token2, "refused")
      assert event["user_status"] == "refused"

      assert event["accepted_count"] == 0
      assert event["invited_count"] == 1
      assert event["refused_count"] == 1

      event = attend.(token3, "doubts")
      assert event["user_status"] == "doubts"

      assert event["accepted_count"] == 0
      assert event["invited_count"] == 0
      assert event["refused_count"] == 1
      assert event["doubts_count"] == 1
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..10, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
