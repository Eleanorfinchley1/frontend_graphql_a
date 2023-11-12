defmodule BillBored.Stubs.AgoraAPI do
  def config(), do: [s3_config: %{}]
  def s3_config(), do: %{}

  def acquire_recording(channel_name, uid) do
    send(self(), {__MODULE__, :acquire_recording, {channel_name, uid}})
    {:ok, %{"resourceId" => "IqCWKgW2CD0KqnZm0lcCz"}}
  end

  def start_recording(channel_name, uid, resource_id, s3_config) do
    send(self(), {__MODULE__, :start_recording, {channel_name, uid, resource_id, s3_config}})

    {:ok,
     %{"resourceId" => "IqCWKgW2CD0KqnZm0lcCz", "sid" => "1967a06b21454d3e5fa67b843ad93bfe"}}
  end

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
         "status" => 5
       }
     }}
  end

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
         "uploadingStatus" => "uploaded"
       }
     }}
  end

  def remove_stream_recordings(sid) do
    send(self(), {__MODULE__, :remove_stream_recordings, {sid}})
    :ok
  end
end