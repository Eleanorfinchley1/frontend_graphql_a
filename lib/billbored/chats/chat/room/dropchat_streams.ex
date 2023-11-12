defmodule BillBored.Chat.Room.DropchatStreams do
  import Ecto.Query
  import BillBored.ServiceRegistry, only: [service: 1]

  alias BillBored.User
  alias BillBored.Chat.Room
  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStream.Speaker, as: DropchatStreamSpeaker
  alias BillBored.Chat.Room.DropchatStream.Reaction, as: DropchatStreamReaction
  alias BillBored.Chat.Room.DropchatStream.SpeakerReaction, as: DropchatStreamSpeakerReaction
  alias BillBored.Chat.Rooms
  alias BillBored.Agora.API, as: AgoraAPI
  alias BillBored.UserPoints

  @recording_uid 4_294_967_295

  def get(stream_id) do
    case Repo.get(DropchatStream, stream_id) do
      %DropchatStream{} = stream -> {:ok, stream}
      _ -> {:error, :not_found}
    end
  end

  def get_active(%Room{id: room_id}) do
    from(s in DropchatStream, where: s.dropchat_id == ^room_id and s.status == "active")
    |> Repo.one()
  end

  def list(%Room{id: room_id}) do
    from(s in DropchatStream,
      left_join: sp in assoc(s, :speakers),
      where: s.dropchat_id == ^room_id,
      order_by: [desc: s.inserted_at],
      preload: [speakers: sp]
    )
    |> Repo.all()
  end

  def list_with_recordings_for(user_id, params \\ %{}) do
    from(s in DropchatStream,
      join: d in assoc(s, :dropchat),
      where: s.admin_id == ^user_id and not is_nil(s.recording_data),
      order_by: [desc: s.inserted_at],
      preload: [dropchat: d]
    )
    |> Repo.paginate(params)
  end

  def list_active() do
    from(s in DropchatStream,
      where: s.status == "active",
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
  end

  def stream_available_minutes(user_id) do
    free_minutes = daily_free_minutes()
    total_stream_minutes = daily_stream_minutes(user_id)
    points_available_minutes = UserPoints.stream_available_minutes_with_points(user_id)
    if (free_minutes < total_stream_minutes) do
      points_available_minutes
    else
      points_available_minutes + free_minutes - total_stream_minutes
    end
  end

  def start(%Room{} = room, %User{} = admin, title) do
    if stream_available_minutes(admin.id) > 0 do
      result =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:check_admin, fn _, _ ->
          if Rooms.admin?(room, admin) do
            {:ok, admin}
          else
            {:error, :user_not_admin}
          end
        end)
        |> Ecto.Multi.run(:check_active_stream, fn _, _ ->
          case get_active(room) do
            %DropchatStream{} -> {:error, :active_stream_exists}
            _ -> {:ok, nil}
          end
        end)
        |> Ecto.Multi.run(:create_stream, fn _, _ ->
          %DropchatStream{}
          |> DropchatStream.create_changeset(%{
            dropchat: room,
            admin: admin,
            title: title,
            status: "active"
          })
          |> Repo.insert()
        end)
        |> Ecto.Multi.run(:add_admin_speaker, fn _, %{create_stream: stream} ->
          %DropchatStreamSpeaker{}
          |> DropchatStreamSpeaker.changeset(%{stream_id: stream.id, user_id: admin.id})
          |> Repo.insert(conflict_target: [:stream_id, :user_id], on_conflict: :nothing)
        end)
        |> Repo.transaction()

      with {:ok, %{create_stream: dropchat_stream}} <- result do
        candidate = BillBored.AnticipationCandidates.candidate_user(dropchat_stream.admin_id, dropchat_stream.title)

        if not is_nil(candidate) do
          UserPoints.double_points_by_anticipation(dropchat_stream.admin_id)
          BillBored.AnticipationCandidates.update(candidate, %{rewarded: true})
        end

        {:ok, dropchat_stream}
      end
    else
      {false, :insufficient_streaming_points}
    end
  end

  def finish(%DropchatStream{} = dropchat_stream) do
    with {:ok, updated_stream} <- maybe_stop_recording(dropchat_stream) do
      now = DateTime.utc_now()
      daily_minutes = daily_stream_minutes(dropchat_stream.admin_id, now)

      stream_minutes = ceil(Time.diff(now, dropchat_stream.inserted_at) / 60)

      if daily_minutes <= daily_free_minutes() do
      else
        if daily_minutes < daily_free_minutes() + stream_minutes do
          UserPoints.reduce_during_streaming(dropchat_stream.admin_id, daily_minutes - daily_free_minutes())
        else
          UserPoints.reduce_during_streaming(dropchat_stream.admin_id, stream_minutes)
        end
      end
      UserPoints.give_peak_points(dropchat_stream)
      updated_stream
      |> DropchatStream.update_changeset(%{status: "finished", finished_at: now})
      |> Repo.update()
    else
      {:error, reason} when is_atom(reason) ->
        UserPoints.reduce_during_streaming(dropchat_stream.admin_id, ceil(Time.diff(DateTime.utc_now(), dropchat_stream.inserted_at) / 60))
        UserPoints.give_peak_points(dropchat_stream)
        dropchat_stream
        |> DropchatStream.update_changeset(%{status: "finished", finished_at: DateTime.utc_now()})
        |> Repo.update()

      error ->
        error
    end
  end

  defp maybe_stop_recording(%DropchatStream{} = dropchat_stream) do
    case dropchat_stream.recording_data do
      %DropchatStream.RecordingData{status: status} when status in ~w(started in_progress) ->
        room = Rooms.get!(dropchat_stream.dropchat_id)
        stop_recording(room, dropchat_stream)

      _ ->
        {:ok, dropchat_stream}
    end
  end

  def remove_recording(%DropchatStream{} = dropchat_stream) do
    with {:ok, dropchat_stream} <- maybe_stop_recording(dropchat_stream),
         :ok <- maybe_remove_recording(dropchat_stream.recording_data) do
      dropchat_stream
      |> DropchatStream.update_changeset(%{recording_data: nil, recording_updated_at: nil})
      |> Repo.update()
    end
  end

  defp maybe_remove_recording(%DropchatStream.RecordingData{sid: sid}) do
    service(AgoraAPI).remove_stream_recordings(sid)
  end

  defp maybe_remove_recording(_), do: :ok

  def stream_speaker?(stream_id, user_id) when is_integer(stream_id) and is_integer(user_id) do
    speakers_count =
      from(s in DropchatStreamSpeaker,
        where: s.stream_id == ^stream_id and s.user_id != ^user_id
      )
      |> Repo.aggregate(:count)
    speakers_count > 0
  end

  def add_speaker(%DropchatStream{id: stream_id}, user_id, max_speakers, is_ghost \\ false) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:check_limit, fn _, _ ->
        speakers_count =
          from(s in DropchatStreamSpeaker,
            where: s.stream_id == ^stream_id and s.user_id != ^user_id
          )
          |> Repo.aggregate(:count)

        if speakers_count >= max_speakers do
          {:error, :speakers_limit_reached}
        else
          {:ok, speakers_count}
        end
      end)
      |> Ecto.Multi.run(:add_speaker, fn _, _ ->
        %DropchatStreamSpeaker{}
        |> DropchatStreamSpeaker.changeset(%{stream_id: stream_id, user_id: user_id, is_ghost: is_ghost})
        |> Repo.insert(conflict_target: [:stream_id, :user_id], on_conflict: :nothing)
      end)
      |> Repo.transaction()

    with {:ok, %{add_speaker: speaker}} <- result do
      {:ok, speaker}
    end
  end

  def remove_speaker(%DropchatStream{id: stream_id}, user_id) do
    from(s in DropchatStreamSpeaker, where: s.stream_id == ^stream_id and s.user_id == ^user_id)
    |> Repo.delete_all()
  end

  def user_reactions(%DropchatStream{id: stream_id}, user_id) do
    from(r in DropchatStreamReaction,
      where: r.stream_id == ^stream_id and r.user_id == ^user_id,
      select: %{
        type: r.type,
        count: count(r.id)
      },
      group_by: [r.type]
    )
    |> Repo.all()
    |> Enum.map(fn %{type: type, count: count} -> {type, count > 0} end)
    |> Enum.into(%{
      "like" => false,
      "dislike" => false
    })
  end

  def add_reaction(%DropchatStream{id: stream_id, admin: %User{id: admin_id}} = stream, user_id, type, speaker_id \\ nil) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:insert_reaction, fn _, _ ->
        case type do
          "clapping" ->
            speaker_id = speaker_id || admin_id
            if speaker_id == user_id do
              {:error, "You can't clap your speaking"}
            else
              speakers_count =
                from(s in DropchatStreamSpeaker,
                  where: s.stream_id == ^stream_id and s.user_id == ^speaker_id
                )
                |> Repo.aggregate(:count)

              if speakers_count > 0 do
                %DropchatStreamSpeakerReaction{}
                |> DropchatStreamSpeakerReaction.changeset(%{stream_id: stream_id, user_id: user_id, speaker_id: speaker_id, type: type})
                |> Repo.insert()
              else
                {:error, "Incorrect Speaker"}
              end
            end
          _ ->
            %DropchatStreamReaction{}
            |> DropchatStreamReaction.changeset(%{stream_id: stream_id, user_id: user_id, type: type})
            |> Repo.insert(conflict_target: [:stream_id, :user_id, :type], on_conflict: :nothing)
        end
      end)
      |> Ecto.Multi.run(:update_count, fn _, %{insert_reaction: reaction} ->
        updated_stream =
          if !is_nil(reaction.id) do
            {_, [updated_stream]} =
              from(s in DropchatStream,
                where: s.id == ^stream_id,
                update: [
                  set: [
                    reactions_count:
                      fragment(
                        "jsonb_set(COALESCE(?, '{}'::jsonb), ?::text[], (COALESCE(?->>?, '0')::int + 1)::text::jsonb, true)",
                        s.reactions_count,
                        [^type],
                        s.reactions_count,
                        ^type
                      )
                  ]
                ],
                select: s
              )
              |> Repo.update_all([])

            updated_stream
          else
            stream
          end

        {:ok,
         %DropchatStream{updated_stream | user_reactions: user_reactions(updated_stream, user_id)}}
      end)
      |> Repo.transaction()

    with {:ok, %{update_count: updated_stream}} <- result do
      {:ok, updated_stream}
    end
  end

  def remove_reaction(%DropchatStream{id: stream_id} = stream, user_id, type) do
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:check_type, fn _, _ ->
        if type in DropchatStreamReaction.valid_types() do
          {:ok, type}
        else
          {:error, :invalid_params}
        end
      end)
      |> Ecto.Multi.run(:delete_like, fn _, _ ->
        {count, _} =
          from(r in DropchatStreamReaction,
            where: r.stream_id == ^stream_id and r.user_id == ^user_id and r.type == ^type
          )
          |> Repo.delete_all()

        {:ok, count}
      end)
      |> Ecto.Multi.run(:update_count, fn
        _, %{delete_like: count} when count > 0 ->
          {_, [updated_stream]} =
            from(s in DropchatStream,
              where: s.id == ^stream_id,
              update: [
                set: [
                  reactions_count:
                    fragment(
                      "jsonb_set(?, ?::text[], (COALESCE(?->>?, '0')::int - 1)::text::jsonb)",
                      s.reactions_count,
                      [^type],
                      s.reactions_count,
                      ^type
                    )
                ]
              ],
              select: s
            )
            |> Repo.update_all([])

          {:ok, updated_stream}

        _, _ ->
          {:ok, stream}
      end)
      |> Repo.transaction()

    with {:ok, %{update_count: updated_stream}} <- result do
      {:ok, updated_stream}
    end
  end

  @live_audience_key_ttl "86400"
  @live_audience_member_ttl 90

  def live_audience_key(stream_id), do: "dropchat:stream:#{stream_id}:live_audience"

  def live_audience_count(%DropchatStream{id: stream_id}) do
    key = live_audience_key(stream_id)
    now_ts = DateTime.to_unix(DateTime.utc_now())
    from_ts = now_ts - @live_audience_member_ttl

    with {:ok, count} <-
           service(BillBored.Redix).command(["ZCOUNT", key, to_string(from_ts), to_string(now_ts)]) do
      count
    else
      _ ->
        0
    end
  end

  def add_live_audience_member(%DropchatStream{id: stream_id}, user_id) do
    key = live_audience_key(stream_id)
    now_ts = DateTime.to_unix(DateTime.utc_now())

    commands = [
      ["ZADD", key, to_string(now_ts), to_string(user_id)],
      ["EXPIRE", key, @live_audience_key_ttl]
    ]

    with {:ok, _} <- service(BillBored.Redix).pipeline(commands) do
      :ok
    end
  end

  def remove_live_audience_member(%DropchatStream{id: stream_id}, user_id) do
    key = live_audience_key(stream_id)

    with {:ok, _} <- service(BillBored.Redix).command(["ZREM", key, to_string(user_id)]) do
      :ok
    end
  end

  @stream_ping_key_ttl "86400"

  def dropchat_stream_ping_key(stream_id, pinger_id, pinged_user_id), do: "dropchat:stream:#{stream_id}:ping:#{pinger_id}:#{pinged_user_id}"

  def user_pinged?(%DropchatStream{id: stream_id}, user_id, ping_user_id) do
    key = dropchat_stream_ping_key(stream_id, user_id, ping_user_id)
    case service(BillBored.Redix).command(["EXISTS", key]) do
      {:ok, 1} -> true
      _ -> false
    end
  end

  def ping_user(%DropchatStream{id: stream_id} = stream, user_id, ping_user_id) do
    with {:ok, user_to_ping} <- validate_follower(user_id, ping_user_id),
         :ok <- validate_user_not_pinged(stream, user_id, ping_user_id) do
      key = dropchat_stream_ping_key(stream_id, user_id, ping_user_id)
      now_ts = DateTime.to_unix(Timex.now())
      {:ok, "OK"} = service(BillBored.Redix).command(["SETEX", key, @stream_ping_key_ttl, to_string(now_ts)])

      service(Notifications).process_dropchat_stream_pinged(%{
        stream: stream |> Repo.preload(:dropchat),
        pinger_user: BillBored.Users.get!(user_id),
        pinged_user: user_to_ping |> Repo.preload(:devices),
      })
    end
  end

  def replace_flags(%DropchatStream{id: stream_id}, replace, remove \\ []) do
    Repo.transaction(fn _ ->
      stream = Repo.get!(DropchatStream, stream_id)

      new_flags =
        stream.flags
        |> Map.drop(remove)
        |> Map.merge(replace)

      DropchatStream.update_changeset(stream, %{flags: new_flags})
      |> Repo.update!()
    end)
  end

  def update_flags(%DropchatStream{id: stream_id}, flags, update_fun) do
    Repo.transaction(fn _ ->
      stream = Repo.get!(DropchatStream, stream_id)

      updated_flags =
        Enum.reduce(flags, %{}, fn flag, acc ->
          Map.put(acc, flag, update_fun.(flag, stream.flags[flag]))
        end)

      DropchatStream.update_changeset(stream, %{flags: Map.merge(stream.flags, updated_flags)})
      |> Repo.update!()
    end)
  end

  def start_recording(
        %Room{key: room_key},
        %DropchatStream{key: stream_key, status: "active"} = stream
      ) do
    channel_name = "#{room_key}:#{stream_key}"

    with :ok <- validate_recording_not_started(stream),
         {:ok, %{"resourceId" => resource_id}} <-
           service(AgoraAPI).acquire_recording(channel_name, @recording_uid),
         s3_config <- service(AgoraAPI).s3_config(),
         {:ok, %{"resourceId" => resource_id, "sid" => sid}} <-
           service(AgoraAPI).start_recording(channel_name, @recording_uid, resource_id, s3_config) do
      recording_data = %DropchatStream.RecordingData{
        status: "started",
        uid: to_string(@recording_uid),
        resource_id: resource_id,
        sid: sid
      }

      Ecto.Changeset.change(stream, %{recording_updated_at: DateTime.utc_now()})
      |> Ecto.Changeset.put_embed(:recording_data, recording_data)
      |> Repo.update()
    end
  end

  def update_recording_status(%DropchatStream{} = stream) do
    with {:ok, %DropchatStream.RecordingData{sid: sid, resource_id: resource_id}} <-
           validate_recording_state(stream.recording_data, ~w(started in_progress)),
         {:ok, response} <- service(AgoraAPI).recording_status(sid, resource_id) do
      if get_in(response, ["serverResponse", "status"]) == 5 do
        Ecto.Changeset.change(stream, %{
          recording_updated_at: DateTime.utc_now(),
          recording_data: %{
            status: "in_progress",
            files: get_in(response, ["serverResponse", "fileList"])
          }
        })
        |> Repo.update()
      else
        {:ok, stream}
      end
    end
  end

  def stop_recording(
        %Room{key: room_key},
        %DropchatStream{key: stream_key, status: "active"} = stream
      ) do
    channel_name = "#{room_key}:#{stream_key}"

    with {:ok, %DropchatStream.RecordingData{sid: sid, resource_id: resource_id}} <-
           validate_recording_state(stream.recording_data, ~w(started in_progress)),
         {:ok, response} <-
           service(AgoraAPI).stop_recording(sid, resource_id, channel_name, @recording_uid) do
      if get_in(response, ["serverResponse", "uploadingStatus"]) in ["uploaded", "backuped"] do
        Ecto.Changeset.change(stream, %{
          recording_updated_at: DateTime.utc_now(),
          recording_data: %{
            status: "finished",
            files: get_in(response, ["serverResponse", "fileList"])
          }
        })
        |> Repo.update()
      else
        Ecto.Changeset.change(stream, %{
          recording_updated_at: DateTime.utc_now(),
          recording_data: %{
            status: "failed",
            files: get_in(response, ["serverResponse", "fileList"])
          }
        })
        |> Repo.update()
      end
    end
  end

  def can_free_streams(admin_id, now \\ DateTime.utc_now()) do
    daily_stream_minutes(admin_id, now) < daily_free_minutes()
  end

  def daily_stream_minutes(admin_id, now \\ DateTime.utc_now()) do
    after_created = %{now | second: 0, minute: 0, hour: 0}

    entity = from(d in DropchatStream,
      where: d.admin_id == ^admin_id,
      where: d.status == "finished" and d.finished_at >= ^after_created or d.status == "active",
      select: %{
        minutes: fragment("coalesce(sum(CEIL(EXTRACT(EPOCH FROM AGE(coalesce(?, ?), GREATEST(?, ?))) / 60))::integer, 0)", d.finished_at, ^now, d.inserted_at, ^after_created)
      }
    )
    |> Repo.one()

    (entity || %{minutes: 0})
    |> Map.get(:minutes, 0)
  end

  defp validate_recording_not_started(%DropchatStream{recording_data: nil}), do: :ok

  defp validate_recording_not_started(%DropchatStream{recording_data: %{}}),
    do: {:error, :unexpected_recording_status}

  defp validate_recording_state(
         %DropchatStream.RecordingData{status: status} = recording_data,
         expected_statuses
       ) do
    if status in expected_statuses do
      {:ok, recording_data}
    else
      {:error, :unexpected_recording_status}
    end
  end

  defp validate_recording_state(_, _), do: {:error, :unexpected_recording_status}

  defp validate_follower(user_id, follower_id) do
    User.available(%{for_id: user_id})
    |> join(:inner, [u], f in User.Followings.Following, on: u.id == f.from_userprofile_id)
    |> where([..., f], f.from_userprofile_id == ^follower_id and f.to_userprofile_id == ^user_id)
    |> Repo.one()
    |> case do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :invalid_user}
    end
  end

  defp validate_user_not_pinged(stream, user_id, ping_user_id) do
    case user_pinged?(stream, user_id, ping_user_id) do
      false -> :ok
      true -> {:error, :already_sent}
    end
  end

  def daily_free_minutes() do
    get_in(Application.get_env(:billbored, __MODULE__), [:daily_free_minutes]) ||
      raise("missing #{__MODULE__} daily_free_minutes")
  end

  def protect_speakers_in_stream(%DropchatStream{} = stream) do
    if stream.through_speakers && stream.speakers && Ecto.assoc_loaded?(stream.through_speakers) && Ecto.assoc_loaded?(stream.speakers) do
      updated_stream = %DropchatStream{
        stream
        | speakers: Enum.map(stream.through_speakers, fn through ->
          %User{
            through.user
            | username: if(through.is_ghost, do: anomyous_name(through.user.id), else: through.user.username),
            first_name: if(through.is_ghost, do: "", else: through.user.first_name),
            last_name: if(through.is_ghost, do: "", else: through.user.last_name),
            avatar: if(through.is_ghost, do: "avatars/ghost.jpg", else: through.user.avatar),
            avatar_thumbnail: if(through.is_ghost, do: "avatars/ghost.jpg", else: through.user.avatar_thumbnail),
            is_ghost: through.is_ghost
          }
        end)
      }

      Map.delete(updated_stream, :through_speakers)
    else
      stream
    end
  end

  def anomyous_name(num) when is_integer(num) do
    <<head::binary-size(3), tail::binary>> =
      Integer.to_string(num)
      |> String.pad_leading(6, "0")
      |> String.slice(-6, 6)

    head_match_string =
      head
      |> String.graphemes()
      |> Enum.map(fn <<code>> -> <<code + 49>> end)
      |> List.to_string()

    "Ano_#{head_match_string}_#{tail}"
  end

  def speaker_reactions(speaker_id) when is_integer(speaker_id) do
    DropchatStreamSpeakerReaction
    |> where([sr], sr.speaker_id == ^speaker_id)
    |> group_by([sr], sr.type)
    |> select([sr], %{
      count: fragment("COUNT(?)", sr.id),
      type: sr.type
    })
    |> Repo.all()
  end
end
