defmodule Web.DropchatControllerTest do
  use Web.ConnCase, async: true
  alias BillBored.{User, Chat}
  alias BillBored.Chat.Room.DropchatStream

  describe "grant_request" do
    setup [:create_dropchat, :create_users, :create_administratorship, :create_request]

    test "with valid params", %{
      conn: conn,
      dropchat: dropchat,
      request: request,
      administratorship: %{token: token}
    } do
      # verify that the privelege is not yet granted
      refute Repo.get_by(
               Chat.Room.ElevatedPrivilege,
               user_id: request.user.id,
               dropchat_id: dropchat.id
             )

      resp =
        conn
        |> authenticate(%BillBored.User.AuthToken{key: token})
        |> post(Routes.dropchat_path(conn, :grant_request), %{"request_id" => request.id})
        |> response(200)

      # get created privelege id to check the response
      assert %Chat.Room.ElevatedPrivilege{id: granted_privilege_id} =
               Repo.get_by(
                 Chat.Room.ElevatedPrivilege,
                 user_id: request.user.id,
                 dropchat_id: dropchat.id
               )

      assert Jason.decode!(resp) == %{"granted_privilege" => %{"id" => granted_privilege_id}}
    end

    test "when not admin", %{
      conn: conn,
      non_administratorship: %{token: token},
      dropchat: dropchat,
      request: request
    } do
      # verify that the privelege is not yet granted
      refute Repo.get_by(
               Chat.Room.ElevatedPrivilege,
               user_id: request.user.id,
               dropchat_id: dropchat.id
             )

      resp =
        conn
        |> authenticate(%BillBored.User.AuthToken{key: token})
        |> post(Routes.dropchat_path(conn, :grant_request), %{"request_id" => request.id})
        |> response(403)

      # verify that the privelege is still not granted after unauthorized request
      refute Repo.get_by(
               Chat.Room.ElevatedPrivilege,
               user_id: request.user.id,
               dropchat_id: dropchat.id
             )

      assert resp == "{\"error\":\"not an admin\"}"
    end

    test "when request doesn't exist", %{
      conn: conn,
      administratorship: %{token: token},
      request: request
    } do
      resp =
        conn
        |> authenticate(%BillBored.User.AuthToken{key: token})
        |> post(Routes.dropchat_path(conn, :grant_request), %{"request_id" => request.id + 100})
        |> response(404)

      assert resp == "{\"error\":\"request not found\"}"
    end
  end

  describe "user_stream_recordings" do
    setup [:create_dropchat]

    test "with valid params", %{
      conn: conn,
      dropchat: dropchat
    } do
      user = insert(:user)

      %{id: s1_id} =
        insert(:dropchat_stream,
          admin: user,
          dropchat: dropchat,
          status: "finished",
          recording_data: %Chat.Room.DropchatStream.RecordingData{
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
          }
        )

      assert %{
               "entries" => [%{"id" => ^s1_id} = entry],
               "page_number" => 1,
               "page_size" => 5,
               "total_entries" => 1,
               "total_pages" => 1
             } =
               conn
               |> authenticate()
               |> get(
                 Routes.dropchat_path(conn, :user_stream_recordings) <>
                   "?" <>
                   URI.encode_query(%{
                     "user_id" => user.id,
                     "page_size" => 5
                   })
               )
               |> doc()
               |> json_response(200)

      assert %{
               "recording" => %{
                 "status" => "finished",
                 "urls" => ["https://test-bucket.aws/sid_channel_name.m3u8"]
               },
               "peak_audience_count" => 0
             } = entry
    end

    test "returns error when user_id is missing", %{conn: conn} do
      assert %{
               "error" => "missing_required_params",
               "reason" => "Missing required params: user_id",
               "success" => false
             } =
               conn
               |> authenticate()
               |> get(Routes.dropchat_path(conn, :user_stream_recordings))
               |> json_response(422)
    end
  end

  describe "remove_stream_recordings" do
    setup [:create_dropchat, :create_users, :create_administratorship]

    test "removes stream recordings", %{
      conn: conn,
      dropchat: dropchat,
      administratorship: %{user: admin, token: admin_token}
    } do
      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          admin: admin,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "finished"
          }
        )

      assert %{
               "success" => true
             } =
               conn
               |> authenticate(admin_token)
               |> delete(Routes.dropchat_path(conn, :remove_stream_recordings, dropchat_stream.id))
               |> doc()
               |> json_response(200)

      assert %{
               recording_data: nil,
               recording_updated_at: nil
             } = Repo.get(DropchatStream, dropchat_stream.id)
    end

    test "returns 403 for non admin", %{conn: conn, dropchat: dropchat} do
      dropchat_stream = insert(:dropchat_stream, dropchat: dropchat)

      assert %{
               "success" => false
             } =
               conn
               |> authenticate()
               |> delete(Routes.dropchat_path(conn, :remove_stream_recordings, dropchat_stream.id))
               |> doc()
               |> json_response(403)
    end
  end

  describe "dropchat_list" do
    setup do
      location = %BillBored.Geo.Point{lat: 40.5, long: -50.0}
      chat1 = insert(:chat_room, chat_type: "dropchat", location: location, private: false, created: ~U[2022-01-01 00:00:00Z])
      chat2 = insert(:chat_room, chat_type: "dropchat", location: location, private: false)
      insert(:chat_room, chat_type: "dropchat", location: location, private: true)
      user = insert(:user)

      %{location: location, dropchats: [chat1, chat2], user: user}
    end

    test "with valid params", %{
      conn: conn,
      user: user,
      dropchats: [%{id: chat1_id}, %{id: chat2_id}]
    } do
      assert %{"rooms" => [
        %{"id" => ^chat2_id},
        %{"id" => ^chat1_id},
      ]} =
        conn
        |> authenticate(user)
        |> post(Routes.dropchat_path(conn, :dropchat_list), %{"page" => 1, "page_size" => 2})
        |> doc()
        |> json_response(200)
    end

    test "doesn't return private chats", %{
      conn: conn,
      user: user
    } do
      assert %{"rooms" => []} =
        conn
        |> authenticate(user)
        |> post(Routes.dropchat_path(conn, :dropchat_list), %{"page" => 2, "page_size" => 2})
        |> doc()
        |> json_response(200)
    end

    test "returns error on invalid params", %{
      conn: conn,
      user: user
    } do
      assert %{
        "error" => "invalid_param_type",
        "reason" => "invalid_param_type",
        "success" => false
      } =
        conn
        |> authenticate(user)
        |> post(Routes.dropchat_path(conn, :dropchat_list), %{"page" => "first"})
        |> doc()
        |> json_response(422)
    end
  end

  defp create_users(_context) do
    %User.AuthToken{user: %User{} = admin, key: admin_token_key} = insert(:auth_token)
    %User.AuthToken{user: %User{} = non_admin, key: non_admin_token_key} = insert(:auth_token)
    %User{} = requester = insert(:user)

    {:ok,
     %{
       administratorship: %{user: admin, token: admin_token_key},
       requester: requester,
       non_administratorship: %{user: non_admin, token: non_admin_token_key}
     }}
  end

  defp create_administratorship(%{dropchat: dropchat, administratorship: %{user: admin}}) do
    %Chat.Room.Administratorship{} =
      insert(:chat_room_administratorship, room: dropchat, user: admin)

    :ok
  end

  defp create_dropchat(_context) do
    %Chat.Room{} =
      dropchat =
      insert(
        :chat_room,
        chat_type: "dropchat",
        location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
        private: false
      )

    {:ok, %{dropchat: dropchat}}
  end

  defp create_request(%{dropchat: dropchat, requester: requester}) do
    %Chat.Room.ElevatedPrivilege.Request{} =
      request = insert(:chat_room_elevated_privileges_request, room: dropchat, user: requester)

    {:ok, %{request: request}}
  end
end
