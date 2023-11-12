defmodule Web.PointRequestControllerTest do
  use Web.ConnCase, async: true

  import BillBored.Factory

  import BillBored.ServiceRegistry, only: [replace: 2]

  alias BillBored.{User, UserPoints, UserPointRequests, Chat.Room.DropchatStream.RecordingData}

  setup [:create_users]

  describe "the notification when points are" do
    use Phoenix.ChannelTest

    # defp join_notifications_channel(%User.AuthToken{user: %User{} = user, key: token}) do
    #   {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})
    #   subscribe_and_join(socket, "notifications:#{user.id}", %{})
    # end

    test "requested to friends", %{conn: conn, tokens: [author1, author2, author3, _ | _]} do
      insert(:user_following, from: author1.user, to: author2.user)
      insert(:user_following, from: author2.user, to: author1.user)
      insert(:user_following, from: author1.user, to: author3.user)
      insert(:user_following, from: author3.user, to: author1.user)

      topic1 = "notifications:#{author2.user_id}"
      Web.Endpoint.subscribe(topic1)

      topic2 = "notifications:#{author3.user_id}"
      Web.Endpoint.subscribe(topic2)

      # {:ok, _reply, _socket} = join_notifications_channel(author2)
      # {:ok, _reply, _socket} = join_notifications_channel(author3)

      conn
        |> authenticate(author1)
        |> post(Routes.point_request_path(conn, :create))
        |> json_response(200)

      # assert_push("points:request", payload)

      assert_received %Phoenix.Socket.Broadcast{
        event: "points:request",
        payload: payload,
        topic: ^topic1
      }

      assert_received %Phoenix.Socket.Broadcast{
        event: "points:request",
        payload: payload,
        topic: ^topic2
      }
    end

    test "donated", %{conn: conn, tokens: [author1, author2, _ | _]} do
      topic1 = "notifications:#{author1.user_id}"
      Web.Endpoint.subscribe(topic1)

      {:ok, point_request} = UserPointRequests.create(%{}, user_id: author1.user_id)
      UserPoints.give_signup_points(author2.user_id)
      conn
        |> authenticate(author2)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(200)
    end

    test "donated and fully consumed on time", %{conn: conn, tokens: [author1, author2, author3, _ | _]} do
      topic1 = "notifications:#{author2.user_id}"
      Web.Endpoint.subscribe(topic1)

      now = DateTime.utc_now()
      {:ok, point_request} = UserPointRequests.create(%{}, user_id: author1.user_id)

      UserPoints.give_signup_points(author2.user_id)
      UserPoints.give_signup_points(author3.user_id)
      conn
        |> authenticate(author2)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(200)
      conn
        |> authenticate(author3)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(200)
      room = insert(
        :chat_room,
        chat_type: "dropchat",
        location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
        private: false
      )
      insert(:dropchat_stream,
          admin: author1.user,
          dropchat: room,
          status: "finished",
          recording_data: %RecordingData{
            status: "finished",
            files: [
              %{
                "fileName" => "sid_channel_name.m3u8",
                "isPlayable" => true,
                "mixedAllUser" => true,
                "sliceStartTime" => 1_623_151_187_267,
                "trackType" => "audio",
                "uid" => "0"
              }
            ]
          },
          inserted_at: DateTime.add(now, 3600),
          finished_at: DateTime.add(now, 3600 + 1000)
        )
      BillBored.Workers.GiveBonusDonationPoints.call(DateTime.add(now, 2 * 3600))
    end
  end

  describe "the failed donation" do
    test "with insuffience points", %{conn: conn, tokens: [author1, author2, _ | _]} do

      {:ok, point_request} = UserPointRequests.create(%{}, user_id: author1.user_id)

      conn
        |> authenticate(author2)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(422)
    end

    test "with itself", %{conn: conn, tokens: [author1, _ | _]} do
      {:ok, point_request} = UserPointRequests.create(%{}, user_id: author1.user_id)
      UserPoints.give_signup_points(author1.user_id)
      conn
        |> authenticate(author1)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(403)
    end

    test "with more than 3 donations", %{conn: conn, tokens: [author1, author2, author3, author4, author5, _ | _]} do
      {:ok, point_request} = UserPointRequests.create(%{}, user_id: author1.user_id)
      UserPoints.give_signup_points(author2.user_id)
      UserPoints.give_signup_points(author3.user_id)
      UserPoints.give_signup_points(author4.user_id)
      UserPoints.give_signup_points(author5.user_id)
      conn
        |> authenticate(author2)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(200)
      conn
        |> authenticate(author3)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(200)
      conn
        |> authenticate(author4)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(200)
      conn
        |> authenticate(author5)
        |> post(Routes.point_request_path(conn, :donate, point_request.id), %{
          "stream_points" => 50
        })
        |> json_response(403)
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..10, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
