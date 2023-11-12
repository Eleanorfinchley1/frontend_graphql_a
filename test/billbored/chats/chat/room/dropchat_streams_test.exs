defmodule BillBored.Chat.Room.DropchatStreamsTest do
  use BillBored.DataCase, async: true

  import BillBored.ServiceRegistry, only: [replace: 2]

  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStream.Reaction, as: DropchatStreamReaction
  alias BillBored.Chat.Room.DropchatStreams
  alias BillBored.UserPoints

  setup do
    dropchat = insert(:chat_room, chat_type: "dropchat")
    admin = insert(:chat_room_administratorship, room: dropchat).user
    UserPoints.give_signup_points(admin.id)
    user = insert(:user)
    UserPoints.give_signup_points(user.id)

    %{dropchat: dropchat, admin: admin, user: user}
  end

  describe "start" do
    test "creates a new active stream", %{dropchat: dropchat, admin: %{id: admin_id} = admin} do
      insert(:dropchat_stream, dropchat: dropchat, admin: admin, status: "finished")

      assert {:ok, %{status: "active"}} = DropchatStreams.start(dropchat, admin, "Hot topic")

      created_stream =
        from(b in DropchatStream,
          where:
            b.dropchat_id == ^dropchat.id and b.admin_id == ^admin.id and b.status == "active"
        )
        |> Repo.one()
        |> Repo.preload(:speakers)

      assert %{key: key, title: "Hot topic"} = created_stream
      assert [%{id: ^admin_id}] = created_stream.speakers
      assert key
    end

    test "doesn't create a stream when another is still active", %{
      dropchat: dropchat,
      admin: admin
    } do
      insert(:dropchat_stream, dropchat: dropchat)

      assert {:error, :check_active_stream, :active_stream_exists, _} =
              DropchatStreams.start(dropchat, admin, "Not today!")
    end

    test "doesn't create a stream when user is not admin", %{dropchat: dropchat} do
      user = insert(:user)
      UserPoints.give_signup_points(user.id)
      assert {:error, :check_admin, :user_not_admin, _} =
              DropchatStreams.start(dropchat, user, "Not today!")
    end
  end

  defmodule Stubs.AgoraAPI.StopRecording.ResourceExpiredError do
    def stop_recording(_sid, _resource_id, _channel_name, _uid) do
      send(self(), {__MODULE__, :stop_recording})
      {:error, :resource_expired}
    end
  end

  describe "finish" do
    setup(%{dropchat: dropchat}) do
      %{
        dropchat_stream: insert(:dropchat_stream, dropchat: dropchat)
      }
    end

    test "finishes active stream", %{dropchat_stream: %{id: dropchat_stream_id} = dropchat_stream} do
      {:ok, _} = DropchatStreams.finish(dropchat_stream)

      assert %{status: "finished", id: dropchat_stream_id} =
               Repo.get!(DropchatStream, dropchat_stream_id)
    end

    test "finishes active stream when agora returns resource expired", %{
      dropchat_stream: %{id: dropchat_stream_id} = dropchat_stream
    } do
      replace(BillBored.Agora.API, Stubs.AgoraAPI.StopRecording.ResourceExpiredError)

      {:ok, dropchat_stream} =
        Ecto.Changeset.change(dropchat_stream, %{
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "started"
          }
        })
        |> Repo.update()

      {:ok, _} = DropchatStreams.finish(dropchat_stream)

      assert_received {Stubs.AgoraAPI.StopRecording.ResourceExpiredError, :stop_recording}

      assert %{status: "finished", id: dropchat_stream_id} =
               Repo.get!(DropchatStream, dropchat_stream_id)
    end
  end

  describe "add_reaction" do
    setup(%{dropchat: dropchat}) do
      %{
        dropchat_stream:
          insert(:dropchat_stream,
            dropchat: dropchat,
            reactions_count: %{"like" => 5, "dislike" => 300}
          )
      }
    end

    test "creates like", %{dropchat_stream: %{id: dropchat_stream_id} = dropchat_stream} do
      %{id: user_id} = insert(:user)

      {:ok, %{reactions_count: %{"like" => 6, "dislike" => 300}}} =
        DropchatStreams.add_reaction(dropchat_stream, user_id, "like")

      assert %{reactions_count: %{"like" => 6, "dislike" => 300}} =
               Repo.get!(DropchatStream, dropchat_stream_id)

      assert %{"like" => true, "dislike" => false} ==
               DropchatStreams.user_reactions(dropchat_stream, user_id)

      assert from(r in DropchatStreamReaction,
               where:
                 r.stream_id == ^dropchat_stream_id and r.user_id == ^user_id and r.type == "like"
             )
             |> Repo.exists?()
    end

    test "doesn't create duplicate like", %{
      dropchat_stream: %{id: dropchat_stream_id} = dropchat_stream
    } do
      %{id: user_id} = user = insert(:user)
      insert(:dropchat_stream_reaction, stream: dropchat_stream, user: user, type: "like")
      {:ok, _} = DropchatStreams.add_reaction(dropchat_stream, user_id, "like")

      assert %{"like" => true, "dislike" => false} ==
               DropchatStreams.user_reactions(dropchat_stream, user_id)

      assert %{reactions_count: %{"like" => 5, "dislike" => 300}} =
               Repo.get!(DropchatStream, dropchat_stream_id)

      assert 1 ==
               from(r in DropchatStreamReaction,
                 where:
                   r.stream_id == ^dropchat_stream_id and r.user_id == ^user_id and
                     r.type == "like"
               )
               |> Repo.aggregate(:count)
    end

    test "creates dislike", %{dropchat_stream: %{id: dropchat_stream_id} = dropchat_stream} do
      %{id: user_id} = insert(:user)
      {:ok, _} = DropchatStreams.add_reaction(dropchat_stream, user_id, "dislike")

      assert %{reactions_count: %{"like" => 5, "dislike" => 301}} =
               Repo.get!(DropchatStream, dropchat_stream_id)

      assert %{"dislike" => true, "like" => false} ==
               DropchatStreams.user_reactions(dropchat_stream, user_id)

      assert from(r in DropchatStreamReaction,
               where:
                 r.stream_id == ^dropchat_stream_id and r.user_id == ^user_id and
                   r.type == "dislike"
             )
             |> Repo.exists?()
    end

    test "works when stream reactions aren't initialized", %{dropchat: dropchat} do
      %{id: dropchat_stream_id} =
        dropchat_stream = insert(:dropchat_stream, dropchat: dropchat, reactions_count: nil)

      %{id: user_id} = insert(:user)
      {:ok, _} = DropchatStreams.add_reaction(dropchat_stream, user_id, "like")

      assert %{reactions_count: %{"like" => 1}} = Repo.get!(DropchatStream, dropchat_stream.id)

      assert %{"like" => true, "dislike" => false} ==
               DropchatStreams.user_reactions(dropchat_stream, user_id)

      assert from(r in DropchatStreamReaction,
               where:
                 r.stream_id == ^dropchat_stream_id and r.user_id == ^user_id and r.type == "like"
             )
             |> Repo.exists?()
    end
  end

  describe "remove_reaction" do
    setup(%{dropchat: dropchat}) do
      %{
        dropchat_stream:
          insert(:dropchat_stream,
            dropchat: dropchat,
            reactions_count: %{"like" => 50, "dislike" => 2}
          )
      }
    end

    test "deletes user like", %{dropchat_stream: %{id: dropchat_stream_id} = dropchat_stream} do
      %{id: user_id} = user = insert(:user)
      insert(:dropchat_stream_reaction, stream: dropchat_stream, user: user, type: "like")
      {:ok, _} = DropchatStreams.remove_reaction(dropchat_stream, user_id, "like")

      assert %{"like" => false, "dislike" => false} ==
               DropchatStreams.user_reactions(dropchat_stream, user_id)

      assert %{reactions_count: %{"like" => 49, "dislike" => 2}} =
               Repo.get!(DropchatStream, dropchat_stream_id)

      refute from(r in DropchatStreamReaction,
               where:
                 r.stream_id == ^dropchat_stream_id and r.user_id == ^user_id and r.type == "like"
             )
             |> Repo.exists?()
    end

    test "works when user like does not exist", %{
      dropchat_stream: %{id: dropchat_stream_id} = dropchat_stream
    } do
      %{id: user_id} = insert(:user)
      {:ok, _} = DropchatStreams.remove_reaction(dropchat_stream, user_id, "like")

      assert %{"like" => false, "dislike" => false} ==
               DropchatStreams.user_reactions(dropchat_stream, user_id)

      assert %{reactions_count: %{"like" => 50, "dislike" => 2}} =
               Repo.get!(DropchatStream, dropchat_stream_id)

      refute from(r in DropchatStreamReaction,
               where:
                 r.stream_id == ^dropchat_stream_id and r.user_id == ^user_id and r.type == "like"
             )
             |> Repo.exists?()
    end

    test "works when stream reactions aren't initialized", %{dropchat: dropchat} do
      dropchat_stream = insert(:dropchat_stream, dropchat: dropchat, reactions_count: nil)

      %{id: user_id} = insert(:user)
      {:ok, _} = DropchatStreams.remove_reaction(dropchat_stream, user_id, "like")

      assert %{"like" => false, "dislike" => false} ==
               DropchatStreams.user_reactions(dropchat_stream, user_id)

      assert %{reactions_count: nil} = Repo.get!(DropchatStream, dropchat_stream.id)
    end
  end

  describe "user_reactions" do
    setup(_context) do
      s1 = insert(:dropchat_stream)
      s2 = insert(:dropchat_stream)

      %{
        streams: [s1, s2]
      }
    end

    test "returns correct reactions count", %{streams: [s1, s2]} do
      %{user_id: r1_user_id} = insert(:dropchat_stream_reaction, stream: s1, type: "like")
      %{user_id: r2_user_id} = insert(:dropchat_stream_reaction, stream: s2, type: "dislike")

      u3 = insert(:user)
      insert(:dropchat_stream_reaction, stream: s2, user: u3, type: "like")
      insert(:dropchat_stream_reaction, stream: s2, user: u3, type: "dislike")

      assert %{"like" => true, "dislike" => false} ==
               DropchatStreams.user_reactions(s1, r1_user_id)

      assert %{"like" => false, "dislike" => true} ==
               DropchatStreams.user_reactions(s2, r2_user_id)

      assert %{"like" => true, "dislike" => true} == DropchatStreams.user_reactions(s2, u3.id)

      assert %{"like" => false, "dislike" => false} ==
               DropchatStreams.user_reactions(s2, r1_user_id)

      assert %{"like" => false, "dislike" => false} == DropchatStreams.user_reactions(s1, u3.id)
    end
  end

  defmodule Stubs.AgoraAPI.AcquireError do
    defdelegate config(), to: BillBored.Stubs.AgoraAPI

    defdelegate start_recording(channel_name, uid, resource_id, s3_config),
      to: BillBored.Stubs.AgoraAPI

    def acquire_recording(channel_name, uid) do
      send(self(), {__MODULE__, :acquire_recording, {channel_name, uid}})
      {:error, %HTTPoison.Response{body: "invalid", status_code: 400}}
    end
  end

  defmodule Stubs.AgoraAPI.StatusError do
    defdelegate config(), to: BillBored.Stubs.AgoraAPI
    defdelegate acquire_recording(channel_name, uid), to: BillBored.Stubs.AgoraAPI

    defdelegate start_recording(channel_name, uid, resource_id, s3_config),
      to: BillBored.Stubs.AgoraAPI

    def recording_status(sid, resource_id) do
      send(self(), {__MODULE__, :recording_status, {sid, resource_id}})
      {:error, %HTTPoison.Response{body: "invalid", status_code: 400}}
    end
  end

  defmodule Stubs.AgoraAPI.InvalidStatus do
    defdelegate config(), to: BillBored.Stubs.AgoraAPI
    defdelegate acquire_recording(channel_name, uid), to: BillBored.Stubs.AgoraAPI

    defdelegate start_recording(channel_name, uid, resource_id, s3_config),
      to: BillBored.Stubs.AgoraAPI

    def recording_status(sid, resource_id) do
      send(self(), {__MODULE__, :recording_status, {sid, resource_id}})

      {:ok,
       %{
         "resourceId" => resource_id,
         "sid" => sid,
         "serverResponse" => %{
           "fileList" => [
             %{
               "fileName" => "#{sid}_channel_name.m3u8",
               "isPlayable" => true,
               "mixedAllUser" => true,
               "sliceStartTime" => 1_623_151_187_267,
               "trackType" => "audio",
               "uid" => "0"
             }
           ],
           "fileListMode" => "json",
           "sliceStartTime" => 1_623_151_187_267,
           "status" => 3
         }
       }}
    end
  end

  defmodule Stubs.AgoraAPI.StopError do
    defdelegate config(), to: BillBored.Stubs.AgoraAPI
    defdelegate acquire_recording(channel_name, uid), to: BillBored.Stubs.AgoraAPI

    defdelegate start_recording(channel_name, uid, resource_id, s3_config),
      to: BillBored.Stubs.AgoraAPI

    def stop_recording(sid, resource_id, channel_name, uid) do
      send(self(), {__MODULE__, :stop_recording, {sid, resource_id, channel_name, uid}})
      {:error, %HTTPoison.Response{body: "invalid", status_code: 400}}
    end
  end

  defmodule Stubs.AgoraAPI.StopUnknown do
    defdelegate config(), to: BillBored.Stubs.AgoraAPI
    defdelegate acquire_recording(channel_name, uid), to: BillBored.Stubs.AgoraAPI

    defdelegate start_recording(channel_name, uid, resource_id, s3_config),
      to: BillBored.Stubs.AgoraAPI

    def stop_recording(sid, resource_id, channel_name, uid) do
      send(self(), {__MODULE__, :stop_recording, {sid, resource_id, channel_name, uid}})

      {:ok,
       %{
         "resourceId" => resource_id,
         "sid" => sid,
         "serverResponse" => %{
           "fileList" => [
             %{
               "fileName" => "#{sid}_channel_name.m3u8",
               "isPlayable" => true,
               "mixedAllUser" => true,
               "sliceStartTime" => 1_623_151_187_267,
               "trackType" => "audio",
               "uid" => "0"
             }
           ],
           "fileListMode" => "json",
           "uploadingStatus" => "unknown"
         }
       }}
    end
  end

  describe "start_recording" do
    setup(%{dropchat: dropchat}) do
      replace(BillBored.Agora.API, BillBored.Stubs.AgoraAPI)

      %{
        dropchat_stream: insert(:dropchat_stream, dropchat: dropchat)
      }
    end

    test "starts recording", %{dropchat: dropchat, dropchat_stream: dropchat_stream} do
      assert {:ok, updated_stream} = DropchatStreams.start_recording(dropchat, dropchat_stream)

      assert %{
               resource_id: "IqCWKgW2CD0KqnZm0lcCz",
               sid: "1967a06b21454d3e5fa67b843ad93bfe",
               files: nil,
               status: "started"
             } = updated_stream.recording_data

      assert updated_stream.recording_updated_at

      assert_received {BillBored.Stubs.AgoraAPI, :acquire_recording, _}
      assert_received {BillBored.Stubs.AgoraAPI, :start_recording, _}
    end

    test "doesn't start recording if acquire fails", %{
      dropchat: dropchat,
      dropchat_stream: dropchat_stream
    } do
      replace(BillBored.Agora.API, Stubs.AgoraAPI.AcquireError)

      assert {:error, _} = DropchatStreams.start_recording(dropchat, dropchat_stream)

      assert_received {Stubs.AgoraAPI.AcquireError, :acquire_recording, _}
      refute_received {BillBored.Stubs.AgoraAPI, :start_recording, _}
    end
  end

  describe "update_recording_status" do
    test "updates recording status", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, BillBored.Stubs.AgoraAPI)

      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "started"
          }
        )

      assert {:ok, updated_stream} = DropchatStreams.update_recording_status(dropchat_stream)

      assert %{
               resource_id: "resource_id",
               sid: "sid",
               files: [
                 %{
                   "fileName" => "sid_channel_name.m3u8",
                   "isPlayable" => true,
                   "mixedAllUser" => true,
                   "sliceStartTime" => 1_623_151_187_267,
                   "trackType" => "audio",
                   "uid" => "0"
                 }
               ],
               status: "in_progress"
             } = updated_stream.recording_data

      assert updated_stream.recording_updated_at

      assert_received {BillBored.Stubs.AgoraAPI, :recording_status, {"sid", "resource_id"}}
    end

    test "returns error when recording isn't started", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, BillBored.Stubs.AgoraAPI)

      dropchat_stream = insert(:dropchat_stream, dropchat: dropchat)

      assert {:error, :unexpected_recording_status} =
               DropchatStreams.update_recording_status(dropchat_stream)

      refute_received {BillBored.Stubs.AgoraAPI, :recording_status, _}
    end

    test "returns error when agora returns error", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, Stubs.AgoraAPI.StatusError)

      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "started"
          }
        )

      assert {:error, _} = DropchatStreams.update_recording_status(dropchat_stream)

      assert_received {Stubs.AgoraAPI.StatusError, :recording_status, {"sid", "resource_id"}}
    end

    test "doesn't update stream when recording status != 5", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, Stubs.AgoraAPI.InvalidStatus)

      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "started"
          }
        )

      assert {:ok, updated_stream} = DropchatStreams.update_recording_status(dropchat_stream)

      assert %{
               resource_id: "resource_id",
               sid: "sid",
               files: nil,
               status: "started"
             } = updated_stream.recording_data

      assert updated_stream == dropchat_stream

      assert_received {Stubs.AgoraAPI.InvalidStatus, :recording_status, {"sid", "resource_id"}}
    end
  end

  describe "stop_recording" do
    test "stops recording", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, BillBored.Stubs.AgoraAPI)

      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "in_progress"
          }
        )

      assert {:ok, updated_stream} = DropchatStreams.stop_recording(dropchat, dropchat_stream)

      assert %{
               resource_id: "resource_id",
               sid: "sid",
               files: [
                 %{
                   "fileName" => "sid_channel_name.m3u8",
                   "isPlayable" => true,
                   "mixedAllUser" => true,
                   "sliceStartTime" => 1_623_151_187_267,
                   "trackType" => "audio",
                   "uid" => "0"
                 }
               ],
               status: "finished"
             } = updated_stream.recording_data

      assert updated_stream.recording_updated_at

      assert_received {BillBored.Stubs.AgoraAPI, :stop_recording, {"sid", "resource_id", _, _}}
    end

    test "returns error if stream is not started", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, BillBored.Stubs.AgoraAPI)

      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "failed"
          }
        )

      assert {:error, :unexpected_recording_status} =
               DropchatStreams.stop_recording(dropchat, dropchat_stream)

      refute_received {BillBored.Stubs.AgoraAPI, :stop_recording, _}
    end

    test "returns error on agora error", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, Stubs.AgoraAPI.StopError)

      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "started"
          }
        )

      assert {:error, _} = DropchatStreams.stop_recording(dropchat, dropchat_stream)

      assert_received {Stubs.AgoraAPI.StopError, :stop_recording, {"sid", "resource_id", _, _}}
    end

    test "fails stream when uploadingStatus != uploaded or backuped", %{dropchat: dropchat} do
      replace(BillBored.Agora.API, Stubs.AgoraAPI.StopUnknown)

      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "started"
          }
        )

      assert {:ok, updated_stream} = DropchatStreams.stop_recording(dropchat, dropchat_stream)

      assert %{
               resource_id: "resource_id",
               sid: "sid",
               files: [
                 %{
                   "fileName" => "sid_channel_name.m3u8",
                   "isPlayable" => true,
                   "mixedAllUser" => true,
                   "sliceStartTime" => 1_623_151_187_267,
                   "trackType" => "audio",
                   "uid" => "0"
                 }
               ],
               status: "failed"
             } = updated_stream.recording_data

      assert_received {Stubs.AgoraAPI.StopUnknown, :stop_recording, {"sid", "resource_id", _, _}}
    end
  end

  describe "remove_recording" do
    setup do
      replace(BillBored.Agora.API, BillBored.Stubs.AgoraAPI)
      :ok
    end

    test "removes recording", %{dropchat: dropchat} do
      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "finished"
          }
        )

      assert {:ok, updated_stream} = DropchatStreams.remove_recording(dropchat_stream)

      assert %{
        recording_updated_at: nil,
        recording_data: nil
      } = updated_stream

      refute_received {BillBored.Stubs.AgoraAPI, :stop_recording, {"sid", "resource_id", _, _}}
      assert_received {BillBored.Stubs.AgoraAPI, :remove_stream_recordings, {"sid"}}
    end

    test "stops recording if it is still running", %{dropchat: dropchat} do
      dropchat_stream =
        insert(:dropchat_stream,
          dropchat: dropchat,
          recording_data: %DropchatStream.RecordingData{
            resource_id: "resource_id",
            sid: "sid",
            status: "in_progress"
          }
        )

      assert {:ok, updated_stream} = DropchatStreams.remove_recording(dropchat_stream)

      assert %{
        recording_updated_at: nil,
        recording_data: nil
      } = updated_stream

      assert_received {BillBored.Stubs.AgoraAPI, :stop_recording, {"sid", "resource_id", _, _}}
      assert_received {BillBored.Stubs.AgoraAPI, :remove_stream_recordings, {"sid"}}
    end

    test "returns success when recording_data is empty", %{dropchat: dropchat} do
      dropchat_stream = insert(:dropchat_stream, dropchat: dropchat)
      assert {:ok, updated_stream} = DropchatStreams.remove_recording(dropchat_stream)

      assert %{
        recording_updated_at: nil,
        recording_data: nil
      } = updated_stream

      refute_received {BillBored.Stubs.AgoraAPI, :stop_recording, {"sid", "resource_id", _, _}}
      refute_received {BillBored.Stubs.AgoraAPI, :remove_stream_recordings, {"sid"}}
    end
  end

  describe "list_with_recordings_for" do
    setup(%{admin: admin}) do
      s1 =
        insert(:dropchat_stream,
          admin: admin,
          status: "active",
          recording_data: %DropchatStream.RecordingData{status: "in_progress"}
        )

      s2 =
        insert(:dropchat_stream,
          admin: admin,
          status: "finished",
          inserted_at: Timex.shift(Timex.now(), minutes: -5)
        )

      s3 =
        insert(:dropchat_stream,
          admin: admin,
          status: "finished",
          recording_data: %DropchatStream.RecordingData{
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
          inserted_at: Timex.shift(Timex.now(), minutes: -15)
        )

      # Another user's stream
      _s4 =
        insert(:dropchat_stream,
          status: "active",
          recording_data: %DropchatStream.RecordingData{status: "in_progress"}
        )

      %{streams: [s1, s2, s3]}
    end

    test "returns paginated user's dropchat streams with recordings", %{
      admin: admin,
      streams: [%{id: s1_id}, _s2, %{id: s3_id}]
    } do
      assert %Scrivener.Page{
               entries: entries,
               page_number: 1,
               page_size: 10,
               total_entries: 2,
               total_pages: 1
             } = DropchatStreams.list_with_recordings_for(admin.id)

      assert [
               %{id: ^s1_id} = s1,
               %{id: ^s3_id}
             ] = entries

      assert Ecto.assoc_loaded?(s1.dropchat)
    end

    test "allows pagination", %{
      admin: admin,
      streams: [_s1, _s2, %{id: s3_id}]
    } do
      assert %Scrivener.Page{
               entries: entries,
               page_number: 2,
               page_size: 1,
               total_entries: 2,
               total_pages: 2
             } =
               DropchatStreams.list_with_recordings_for(admin.id, %{"page" => 2, "page_size" => 1})

      assert [
               %{id: ^s3_id}
             ] = entries
    end
  end

  describe "ping_user" do
    setup(%{dropchat: dropchat, admin: admin}) do
      Phoenix.PubSub.subscribe(ExUnit.PubSub, "stubs:notifications")

      %{
        dropchat_stream: insert(:dropchat_stream, admin: admin, dropchat: dropchat)
      }
    end

    test "sends a push notification with stream recommendation", %{
      admin: admin,
      dropchat_stream: dropchat_stream
    } do
      user = insert(:user)
      insert(:user_following, from: user, to: admin)
      assert :ok = DropchatStreams.ping_user(dropchat_stream, admin.id, user.id)

      redis_key = DropchatStreams.dropchat_stream_ping_key(dropchat_stream.id, admin.id, user.id)
      {:ok, 1} = BillBored.Stubs.Redix.command(["EXISTS", redis_key])

      assert_received {:process_dropchat_stream_pinged,
                       [%{stream: stream, pinged_user: pinged_user}]}

      assert stream.id == dropchat_stream.id
      assert pinged_user.id == user.id
      assert Ecto.assoc_loaded?(pinged_user.devices)
    end

    test "returns error if user is not a follower", %{
      admin: admin,
      dropchat_stream: dropchat_stream
    } do
      user = insert(:user)

      assert {:error, :invalid_user} =
               DropchatStreams.ping_user(dropchat_stream, admin.id, user.id)
    end

    test "returns error if user is already pinged", %{
      admin: admin,
      dropchat_stream: dropchat_stream
    } do
      user = insert(:user)
      insert(:user_following, from: user, to: admin)

      redis_key = DropchatStreams.dropchat_stream_ping_key(dropchat_stream.id, admin.id, user.id)
      {:ok, "OK"} = BillBored.Stubs.Redix.command(["SET", redis_key, "1"])

      assert {:error, :already_sent} =
               DropchatStreams.ping_user(dropchat_stream, admin.id, user.id)
    end
  end
end
