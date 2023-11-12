defmodule Web.DropchatChannel do
  use Web, :channel
  use Web.Channels.ChannelTasks

  require Logger
  import BillBored.ServiceRegistry, only: [service: 1]

  alias BillBored.{Chat, User}
  alias BillBored.Chat.Room.DropchatBans
  alias BillBored.Chat.Room.{DropchatStream, DropchatStreams}
  alias Web.DropchatChannel.Policy

  # 30 minutes
  @token_ttl 1800
  @max_speakers 6
  # 5 seconds
  @streaming_time_tick_interval 5_000
  # 30 seconds
  @audience_member_tick_interval 30_000

  @stop_speaking_ttl 2

  @stream_add_speaker_params [
    {"user_id", :user_id, true},
    {"is_ghost", :is_ghost, true}
  ]

  @stream_remove_speaker_params [
    {"user_id", :user_id, true}
  ]

  @stream_flags_update_params [
    {"flag", :flag, true, :string},
    {"value", :value, true, :boolean}
  ]

  @stream_reaction_params [
    {"type", :type, true},
    {"speaker_id", :speaker_id, false, :integer}
  ]

  @stream_recommend_params [
    {"user_id", :user_id, true, :integer}
  ]

  def notify_stream_event(%DropchatStream{} = stream, event) do
    updated_stream = %DropchatStream{
      Repo.preload(stream, [:dropchat, :speakers, :admin])
      | live_audience_count: DropchatStreams.live_audience_count(stream)
    }

    updated_stream = DropchatStreams.protect_speakers_in_stream(updated_stream)

    rendered_stream =
      Web.RoomView.render("dropchat_stream.json", %{
        room: updated_stream.dropchat,
        dropchat_stream: updated_stream
      })

    payload = %{
      rendered_stream: rendered_stream
    }

    Web.Endpoint.broadcast("dropchats:#{stream.dropchat.key}", event, payload)
  end

  @impl true
  def join(
        "dropchats:" <> dropchat_room_key,
        %{"geometry" => %{"type" => "Point"} = geometry},
        %{assigns: %{user: %User{id: user_id} = user}} = socket
      ) do
    %Geo.Point{coordinates: {lat, long}} = Geo.JSON.decode!(geometry)
    user_location = %BillBored.Geo.Point{lat: lat, long: long}
    socket = assign(socket, :location, user_location)

    with {:ok, dropchat} <- get_dropchat_for_user(dropchat_room_key, user_id),
         :ok <- check_ban(dropchat, user) do
      %Chat.Room{id: dropchat_id} = dropchat
      socket = assign(socket, :room, dropchat)

      Chat.Room.ElevatedPrivileges.maybe_create(dropchat, user)
      priveleges = calculate_privileges(dropchat, user)

      socket = assign(socket, :priveleges, priveleges)
      has_membership? = !!Chat.Room.Memberships.get_by(user_id: user_id, room_id: dropchat_id)
      socket = assign(socket, :has_membership?, has_membership?)

      rendered_dropchat = Web.RoomView.render("dropchat.json", %{room: dropchat})

      send(self(), :after_join)

      Phoenix.PubSub.subscribe(Web.PubSub, "user_blocks:#{user_id}")
      Phoenix.PubSub.subscribe(Web.PubSub, "user:#{user_id}:dropchat")

      {:ok, %{"dropchat" => rendered_dropchat, "priveleges" => priveleges},
       maybe_assign_ignore_set(socket)}
    else
      error ->
        channel_error(error)
    end
  end

  def join(
        "dropchats:" <> dropchat_room_key,
        _params,
        %{assigns: %{user: %User{} = user}} = socket
      ) do
    with {:ok, dropchat} <- get_dropchat_for_user(dropchat_room_key, user.id),
         :ok <- check_ban(dropchat, user) do
      socket = assign(socket, :room, dropchat)

      Chat.Room.ElevatedPrivileges.maybe_create(dropchat, user)
      priveleges = calculate_privileges(dropchat, user)

      socket = assign(socket, :priveleges, priveleges)
      socket = assign(socket, :has_membership?, true)

      rendered_dropchat = Web.RoomView.render("dropchat.json", %{room: dropchat})
      send(self(), :after_join)
      {:ok, %{"dropchat" => rendered_dropchat, "priveleges" => priveleges}, socket}
    else
      error ->
        channel_error(error)
    end
  end

  defp calculate_privileges(dropchat, user, is_ghost \\ false) do
    cond do
      is_ghost ->
        [:read, :listen]

      Chat.Rooms.admin?(dropchat, user) ->
        [:read, :write, :listen]

      Chat.Rooms.priveleged_member?(dropchat, user) ->
        [:read, :write, :listen]

      true ->
        [:read, :listen]
    end
  end

  defp channel_error({:error, :dropchat_not_found}) do
    {:error, %{"detail" => "chat for this key doesn't exist"}}
  end

  defp channel_error({:error, :user_banned}) do
    {:error, %{"detail" => "Sorry, you can't join this dropchat because you have been banned."}}
  end

  defp channel_error(_error) do
    {:error, %{"detail" => "An error occured while joining the dropchat."}}
  end

  defp get_dropchat(key) do
    case Chat.Rooms.get_dropchat(key) do
      %Chat.Room{} = dropchat ->
        case dropchat.active_stream do
          %{status: "active"} = stream ->
            updated_stream = %DropchatStream{
              stream
              | live_audience_count: DropchatStreams.live_audience_count(stream)
            }

            updated_stream = DropchatStreams.protect_speakers_in_stream(updated_stream)

            {:ok, %Chat.Room{dropchat | active_stream: updated_stream}}

          _ ->
            {:ok, dropchat}
        end

      _ ->
        {:error, :dropchat_not_found}
    end
  end

  defp get_dropchat_for_user(key, user_id) do
    with {:ok, dropchat} <- get_dropchat(key) do
      case dropchat.active_stream do
        %{status: "active"} = stream ->
          user_reactions = DropchatStreams.user_reactions(stream, user_id)

          {:ok,
           %Chat.Room{
             dropchat
             | active_stream: %DropchatStream{stream | user_reactions: user_reactions}
           }}

        _ ->
          {:ok, dropchat}
      end
    end
  end

  defp check_ban(dropchat, user) do
    if DropchatBans.exists?(dropchat, user) do
      {:error, :user_banned}
    else
      :ok
    end
  end

  @spec maybe_create_membership(Phoenix.Socket.t()) :: Phoenix.Socket.t()
  defp maybe_create_membership(socket)
  defp maybe_create_membership(%{assigns: %{has_membership?: true}} = socket), do: socket

  defp maybe_create_membership(
         %{assigns: %{priveleges: priveleges, has_membership?: false, room: dropchat, user: user}} =
           socket
       ) do
    if :write in priveleges do
      Chat.Room.Memberships.create(user, dropchat)
      assign(socket, :has_membership?, true)
    else
      socket
    end
  end

  @impl true
  def handle_in("members:list", _params, %{assigns: %{user: user, room: %Chat.Room{id: room_id}}} = socket) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    members = Chat.Rooms.list_members(room_id)
    rendered_members = Web.RoomView.render("chat_members.json", %{members: members})
    {:reply, {:ok, rendered_members}, socket}
  end

  def handle_in(
        "priveleges:update",
        %{"request" => "write"},
        %{assigns: %{user: %User{} = requester, room: %Chat.Room{} = room}} = socket
      ) do
    # TODO refactor
    try do
      Chat.Rooms.request_write_privelege!(room, requester)
    rescue
      _ -> :ok
    end

    {:reply, :ok, socket}
  end

  ## NEW MESSAGE

  ## TODO refactor

  def handle_in("message:new", params, %{assigns: %{user: user}} = socket) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    if :write in socket.assigns.priveleges or guest_chat_enabled?(socket) do
      socket = maybe_create_membership(socket)
      handle_message_new(params, socket)
    else
      {:reply, {:error, %{"detail" => "user doesn't have write priveleges"}}, socket}
    end
  end

  ## MESSAGE FETCH

  # TODO refactor
  def handle_in(
        "messages:fetch",
        params,
        %{assigns: %{user: %User{id: user_id} = user, room: %{id: room_id}}} = socket
      ) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    {fetch_direction, message_id} =
      case params do
        %{"after" => %{"id" => message_id}} -> {:after, message_id}
        %{"before" => %{"id" => message_id}} -> {:before, message_id}
      end

    order =
      case params["order"] do
        "desc" -> :desc
        _other -> :asc
      end

    messages =
      if limit = params["limit"] do
        Chat.Messages.fetch(room_id, fetch_direction, message_id, %{
          limit: limit,
          order: order,
          for_id: user_id
        })
      else
        Chat.Messages.fetch(room_id, fetch_direction, message_id, %{order: order, for_id: user_id})
      end

    {:reply,
     {:ok, %{"messages" => Web.MessageView.render("messages.json", %{messages: messages})}},
     socket}
  end

  ## TYPING

  def handle_in(
        "user:typing",
        %{"typing" => typing?},
        %{assigns: %{user: %User{username: username} = user}} = socket
      ) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    {:ok, _ref, new_socket} = update_presence(socket, %{typing: typing?, username: username})
    {:reply, :ok, new_socket}
  end

  ## STREAMS

  def handle_in("stream:start", params, %{assigns: %{room: room, user: user}} = socket) do
    with :ok <- check_no_active_stream(room),
         {:ok, %{title: title}} <- validate_stream_start_params(params),
         {:ok, created_stream} <- DropchatStreams.start(room, user, title) do
      BillBored.Users.top_followers(user.id, 5000)
      |> Enum.chunk_every(1_000)
      |> Enum.each(fn receivers ->
        receivers = receivers |> Repo.preload(:devices)

        service(Notifications).process_dropchat_stream_started(%{
          stream: created_stream,
          receivers: receivers
        })
      end)

      {new_socket, %{rendered_stream: rendered_stream}} =
        stream_event(socket, "stream:started", "stream_started")

      {:reply, {:ok, rendered_stream}, new_socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:finish", _params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, true} <- check_admin(room, user),
         {:ok, active_stream} <- check_active_stream(room),
         {:ok, _finished_stream} <- DropchatStreams.finish(active_stream) do
      {new_socket, %{rendered_stream: rendered_stream}} =
        stream_event(socket, "stream:finished", "stream_finished")

      {:reply, {:ok, rendered_stream}, new_socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:get_token", params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room),
         {:ok, role} <- validate_role(params["role"], socket),
         {:ok, available_streaming_time} <- check_streaming_time(user),
         token_ttl <-
           if(available_streaming_time > @token_ttl,
             do: @token_ttl,
             else: available_streaming_time
           ),
         {:ok, token} <-
           service(BillBored.Agora.Tokens).fetch_user_token(
             user,
             "#{room.key}:#{active_stream.key}",
             token_ttl,
             role
           ) do
      expires_at = Timex.shift(DateTime.utc_now(), seconds: token_ttl)

      {:reply,
       {:ok,
        %{
          "token" => token,
          "expires_at" => expires_at,
          "role" => role,
          "available_streaming_time" => available_streaming_time
        }}, socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:add_speaker", params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room),
         {:ok, %{user_id: speaker_id, is_ghost: is_ghost}} <- validate_params(@stream_add_speaker_params, params),
         true <- Policy.authorize(:add_stream_speaker, user.id, active_stream, speaker_id),
         {:ok, _} <- DropchatStreams.add_speaker(active_stream, speaker_id, @max_speakers, is_ghost) do
      {new_socket, %{rendered_stream: rendered_stream}} =
        stream_event(socket, "stream:speaker_added", "speaker_added")

      {:reply, {:ok, rendered_stream}, new_socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:remove_speaker", params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room),
         {:ok, %{user_id: speaker_id}} <- validate_params(@stream_remove_speaker_params, params),
         true <- Policy.authorize(:remove_stream_speaker, user.id, active_stream, speaker_id),
         {removed_count, _} <- DropchatStreams.remove_speaker(active_stream, speaker_id) do
      if removed_count > 0 do
        {new_socket, %{rendered_stream: rendered_stream}} =
          stream_event(socket, "stream:speaker_removed", "speaker_removed")

        {:reply, {:ok, rendered_stream}, new_socket}
      else
        {:reply,
         {:ok,
          Web.RoomView.render("dropchat_stream.json", %{
            room: room,
            dropchat_stream: active_stream
          })}, socket}
      end
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  defp speaker_redis_prefix_key(room_id) do
    "room#{room_id}:speakers"
  end

  def handle_in("stream:start_speaking", _params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, _active_stream} <- check_active_stream(room),
         true <- DropchatStreams.stream_speaker?(room.id, user.id) do

      service(BillBored.Redix).command([
        "SETEX",
        "#{speaker_redis_prefix_key(room.id)}:#{user.id}",
        to_string(@token_ttl),
        to_string(System.os_time(:second) + @token_ttl)
      ])

      {:noreply, socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:stop_speaking", _params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, _active_stream} <- check_active_stream(room),
         true <- DropchatStreams.stream_speaker?(room.id, user.id) do

      # Expirie speaker in 2 seconds
      service(BillBored.Redix).command([
        "SETEX",
        "#{speaker_redis_prefix_key(room.id)}:#{user.id}",
        to_string(@stop_speaking_ttl),
        to_string(System.os_time(:second) + @stop_speaking_ttl)
      ])

      {:noreply, socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:add_reaction", params, %{assigns: %{room: room, user: user}} = socket) do
    {:ok, [_cursor, speaker_keys]} = service(BillBored.Redix).command(["SCAN", "0", "MATCH", "#{speaker_redis_prefix_key(room.id)}:*"])
    speaker = speaker_keys
      |> Enum.reduce(%{ttl: @token_ttl, speaker_id: nil}, fn key, speaker ->
        {:ok, ttl} = service(BillBored.Redix).command(["TTL", key])
        if ttl > 0 and ttl < speaker.ttl do
          user_id = String.to_integer(String.replace(key, "#{speaker_redis_prefix_key(room.id)}:", ""))
          Map.merge(speaker, %{ttl: ttl, speaker_id: user_id})
        end
      end)

    with {:ok, active_stream} <- check_active_stream(room),
         {:ok, %{type: reaction_type}} <- validate_params(@stream_reaction_params, params),
         {:ok, updated_stream} <-
           DropchatStreams.add_reaction(active_stream, user.id, reaction_type, params["speaker_id"] || speaker.speaker_id) do
      {new_socket, %{rendered_stream: rendered_stream}} =
        stream_event(socket, "stream:updated", "reaction_added")

      rendered_stream =
        Map.put(
          rendered_stream,
          "user_reactions",
          DropchatStreams.user_reactions(updated_stream, user.id)
        )

      {:reply, {:ok, rendered_stream}, new_socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:remove_reaction", params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room),
         {:ok, %{type: reaction_type}} <- validate_params(@stream_reaction_params, params),
         {:ok, updated_stream} <-
           DropchatStreams.remove_reaction(active_stream, user.id, reaction_type) do
      {new_socket, %{rendered_stream: rendered_stream}} =
        stream_event(socket, "stream:updated", "reaction_removed")

      rendered_stream =
        Map.put(
          rendered_stream,
          "user_reactions",
          DropchatStreams.user_reactions(updated_stream, user.id)
        )

      {:reply, {:ok, rendered_stream}, new_socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:streaming:start", _params, socket) do
    new_socket = start_streaming_time(stop_streaming_time(socket))

    available_streaming_time =
      BillBored.Users.get_available_streaming_time(new_socket.assigns[:user])

    {:reply, {:ok, %{"available_streaming_time" => available_streaming_time}}, new_socket}
  end

  def handle_in("stream:streaming:stop", _params, socket) do
    available_streaming_time = BillBored.Users.get_available_streaming_time(socket.assigns[:user])
    {:reply, {:ok, %{"available_streaming_time" => available_streaming_time}}, socket}
  end

  def handle_in("stream:audience:join", _params, %{assigns: %{room: room, user: user}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room) do
      leave_stream = socket.assigns[:audience_stream]

      if !leave_stream || leave_stream.id != active_stream.id do
        if leave_stream,
          do: service(DropchatStreams).remove_audience_member(leave_stream, user.id)

        service(DropchatStreams).add_live_audience_member(active_stream, user.id)

        updated_stream = %DropchatStream{
          active_stream
          | live_audience_count: DropchatStreams.live_audience_count(active_stream),
          peak_audience_count: max(DropchatStreams.live_audience_count(active_stream), active_stream.peak_audience_count)
        }

        {new_socket, %{rendered_stream: rendered_stream}} =
          socket
          |> assign(:audience_stream, updated_stream)
          |> start_audience_timer(updated_stream)
          |> stream_event("stream:updated", "audience_joined", updated_stream)

        {:reply, {:ok, rendered_stream}, new_socket}
      else
        rendered_stream =
          Web.RoomView.render("dropchat_stream.json", %{
            room: room,
            dropchat_stream: active_stream
          })

        {:reply, {:ok, rendered_stream}, socket}
      end
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in(
        "stream:audience:leave",
        _params,
        %{assigns: %{audience_stream: %DropchatStream{id: leave_stream_id}, room: room}} = socket
      ) do
    socket = maybe_leave_audience(socket)

    case check_active_stream(room) do
      {:ok, %{id: ^leave_stream_id} = active_stream} ->
        updated_stream = %DropchatStream{
          active_stream
          | live_audience_count: DropchatStreams.live_audience_count(active_stream)
        }

        {new_socket, _} = stream_event(socket, "stream:updated", "audience_left", updated_stream)
        {:reply, :ok, new_socket}

      _ ->
        {:reply, :ok, socket}
    end
  end

  def handle_in("stream:audience:leave", _params, socket) do
    {:reply, {:error, %{"reason" => :not_audience_member}}, socket}
  end

  def handle_in("stream:flags:update", params, %{assigns: %{room: room}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room),
         {:ok, %{flag: flag, value: value}} <-
           validate_params(@stream_flags_update_params, params),
         :ok <- validate_flag(flag),
         {:ok, _updated_stream} <- DropchatStreams.replace_flags(active_stream, %{flag => value}) do
      {new_socket, %{rendered_stream: rendered_stream}} =
        stream_event(socket, "stream:updated", "flags_updated")

      {:reply, {:ok, rendered_stream}, new_socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in(
      "stream:audience:raise_hand",
      %{"is_ghost" => is_ghost},
      %{assigns: %{user: user, room: room}} = socket
    ) do
    with {:ok, _active_stream} <- check_active_stream(room) do
      if room.ghost_allowed and is_ghost do
        priveleges = calculate_privileges(room, user, true)
        new_socket = assign(socket, :priveleges, priveleges)

        {:ok, _ref, new_socket} = update_presence(new_socket, %{
          hand_raised: true,
          is_ghost: true,
          username: DropchatStreams.anomyous_name(user.id),
          first_name: "",
          last_name: "",
          avatar: "avatars/ghost.jpg",
          avatar_thumbnail: "avatars/ghost.jpg"
        })
        {:reply, :ok, new_socket}
      else
        {:ok, _ref, new_socket} = update_presence(socket, %{hand_raised: true})
        {:reply, :ok, new_socket}
      end
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:audience:lower_hand", _params, %{assigns: %{user: _user, room: _room}} = socket) do
    {:ok, _ref, new_socket} = update_presence(socket, %{hand_raised: false})
    {:reply, :ok, new_socket}
  end

  def handle_in("stream:recording:start", _params, %{assigns: %{room: room}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room) do
      new_socket = run_exclusive_task(socket, "stream:recording:start", {room, active_stream})
      {:noreply, new_socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("stream:recommend", params, %{assigns: %{user: user, room: room}} = socket) do
    with {:ok, active_stream} <- check_active_stream(room),
         {:ok, %{user_id: pinged_user_id}} <- validate_params(@stream_recommend_params, params),
         :ok <- DropchatStreams.ping_user(active_stream, user.id, pinged_user_id) do
      {:reply, :ok, socket}
    else
      error ->
        error_to_reply(error, socket)
    end
  end

  def handle_in("streams:list", _params, %{assigns: %{room: room}} = socket) do
    rendered_streams =
      DropchatStreams.list(room)
      |> Enum.map(fn stream ->
        updated_stream = DropchatStreams.protect_speakers_in_stream(stream)
        Web.RoomView.render("dropchat_stream.json", %{
          room: room,
          dropchat_stream: updated_stream
        })
      end)

    {:reply, {:ok, %{"streams" => rendered_streams}}, socket}
  end

  ## TASKS

  @impl true
  def start_task("stream:recording:start", {room, active_stream}, socket) do
    task =
      Task.async(fn ->
        DropchatStreams.start_recording(room, active_stream)
      end)

    {:ok, task, socket}
  end

  @impl true
  def handle_task("stream:recording:start", :completed, result, socket) do
    case result do
      {:ok, _updated_stream} ->
        {new_socket, %{rendered_stream: rendered_stream}} =
          stream_event(socket, "stream:updated", "recording_started")

        {:reply, {:ok, rendered_stream}, new_socket}

      error ->
        Logger.debug("Failed to start stream recording: #{inspect(error)}")
        {:reply, {:error, %{"reason" => :internal_error}}}
    end
  end

  def handle_task(_name, :cancelled, _params, socket) do
    {:reply, {:error, %{reason: :cancelled}}, socket}
  end

  ## PRESENCE

  @impl true
  def handle_info(
        :after_join,
        %{assigns: %{user: %User{id: user_id, username: username}}} = socket
      ) do
    push(socket, "presence_state", Web.Presence.list(socket))
    {:ok, _ref} = Web.Presence.track(socket, user_id, %{typing: false, username: username})
    {:noreply, assign(socket, :presence, %{typing: false, username: username})}
  end

  def handle_info(
        {:user_blocks_update, %{id: user_id}},
        %{assigns: %{user: %User{id: user_id}}} = socket
      ) do
    {:noreply, maybe_assign_ignore_set(socket)}
  end

  def handle_info(
        {:dropchat_ban, %{user: %User{id: user_id}, room: %Chat.Room{id: dropchat_id}}},
        %{assigns: %{user: %User{id: user_id}, room: %Chat.Room{id: dropchat_id}}} = socket
      ) do
    {:stop, :normal, socket}
  end

  def handle_info({:update_streaming_time, start_ts}, %{assigns: %{room: room}} = socket) do
    new_socket = update_streaming_time(socket, start_ts)

    with {:ok, _} <- check_active_stream(room) do
      {:noreply, start_streaming_time(new_socket)}
    else
      _ ->
        {:noreply, new_socket}
    end
  end

  def handle_info(
        {:refresh_audience_member, %DropchatStream{id: stream_id} = stream},
        %{assigns: %{audience_stream: %DropchatStream{id: stream_id}, user: user}} = socket
      ) do
    service(DropchatStreams).add_live_audience_member(stream, user.id)

    new_socket =
      socket
      |> assign(:audience_timer_ref, false)
      |> start_audience_timer(stream)

    {:noreply, new_socket}
  end

  def handle_info({:refresh_audience_member, _}, socket) do
    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    handle_info_tasks(msg, socket)
  end

  defp error_to_reply({false, reason}, socket) do
    {:reply, {:error, %{"reason" => reason}}, socket}
  end

  defp error_to_reply({:error, :missing_required_params, missing_params}, socket) do
    {:reply,
     {:error,
      %{
        "reason" => :invalid_params,
        "detail" => "missing required params: #{missing_params}"
      }}, socket}
  end

  defp error_to_reply({:error, %Ecto.Changeset{valid?: false}}, socket) do
    {:reply, {:error, %{"reason" => :invalid_params}}, socket}
  end

  defp error_to_reply({:error, reason}, socket) do
    if is_atom(reason) || is_binary(reason) do
      {:reply, {:error, %{"reason" => reason}}, socket}
    else
      Logger.error("Attempt to return reason of complex type: #{inspect(reason)}")
      {:reply, {:error, %{"reason" => :internal_error}}, socket}
    end
  end

  defp error_to_reply({:error, _, %Ecto.Changeset{valid?: false}, _}, socket) do
    {:reply, {:error, %{"reason" => :invalid_params}}, socket}
  end

  defp error_to_reply({:error, _, reason, _}, socket) do
    if is_atom(reason) || is_binary(reason) do
      {:reply, {:error, %{"reason" => reason}}, socket}
    else
      Logger.error("Attempt to return reason of complex type: #{inspect(reason)}")
      {:reply, {:error, %{"reason" => :internal_error}}, socket}
    end
  end

  defp error_to_reply(error, socket) do
    Logger.error("Unexpected error: #{inspect(error)}")
    {:reply, {:error, %{"reason" => :internal_error}}, socket}
  end

  defp stop_streaming_time(%{assigns: %{streaming_time: {timer_ref, start_ts}}} = socket) do
    Process.cancel_timer(timer_ref)
    new_socket = update_streaming_time(socket, start_ts)
    assign(new_socket, :streaming_time, nil)
  end

  defp stop_streaming_time(socket), do: socket

  defp start_streaming_time(socket) do
    now_ts = DateTime.to_unix(DateTime.utc_now())

    timer_ref =
      Process.send_after(self(), {:update_streaming_time, now_ts}, @streaming_time_tick_interval)

    assign(socket, :streaming_time, {timer_ref, now_ts})
  end

  defp start_audience_timer(socket, joined_stream) do
    if socket.assigns[:audience_timer_ref],
      do: Process.cancel_timer(socket.assigns[:audience_timer_ref])

    timer_ref =
      Process.send_after(
        self(),
        {:refresh_audience_member, joined_stream},
        @audience_member_tick_interval
      )

    assign(socket, :audience_timer_ref, timer_ref)
  end

  defp stop_audience_timer(socket) do
    if socket.assigns[:audience_timer_ref],
      do: Process.cancel_timer(socket.assigns[:audience_timer_ref])

    socket
  end

  defp update_streaming_time(%{assigns: %{user: user}} = socket, start_ts) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    now_ts = DateTime.to_unix(DateTime.utc_now())

    {:ok, updated_user} =
      BillBored.Users.subtract_available_streaming_time(user, now_ts - start_ts)

    available_streaming_time = BillBored.Users.get_available_streaming_time(updated_user)

    push(socket, "stream:streaming:tick", %{
      "available_streaming_time" => available_streaming_time
    })

    assign(socket, :user, updated_user)
  end

  defp validate_stream_start_params(%{"title" => title}), do: {:ok, %{title: title}}
  defp validate_stream_start_params(_), do: {:error, :invalid_params}

  defp check_no_active_stream(room) do
    case room.active_stream do
      %{status: "active"} -> {:error, :active_stream_exists}
      _ -> :ok
    end
  end

  defp check_active_stream(room) do
    case room.active_stream do
      %{status: "active"} -> {:ok, room.active_stream}
      _ -> {:error, :no_active_stream}
    end
  end

  defp check_admin(room, user) do
    if Chat.Rooms.admin?(room, user) do
      {:ok, true}
    else
      {:error, :insufficient_privileges}
    end
  end

  defp check_streaming_time(user) do
    available_streaming_time = BillBored.Users.get_available_streaming_time(user)

    if available_streaming_time > 0 do
      {:ok, available_streaming_time}
    else
      {:error, :no_streaming_time_available}
    end
  end

  defp validate_role("subscriber" = role, %{assigns: %{priveleges: privileges}}) do
    if :listen in privileges do
      {:ok, role}
    else
      {:error, :insufficient_privileges}
    end
  end

  defp validate_role("publisher" = role, socket) do
    if user_is_speaker?(socket) do
      {:ok, role}
    else
      {:error, :insufficient_privileges}
    end
  end

  defp validate_role(_role, _assigns), do: {:error, :invalid_role}

  defp validate_flag("handraising_enabled"), do: :ok
  defp validate_flag("guest_chat_enabled"), do: :ok
  defp validate_flag(_), do: {:error, :invalid_flag}

  defp user_is_speaker?(%{assigns: %{user: user, room: room}}) do
    with %DropchatStream{} <- room.active_stream,
         true <-
           Enum.any?(room.active_stream.speakers, fn %{id: speaker_id} ->
             speaker_id == user.id
           end) do
      true
    else
      _ ->
        false
    end
  end

  defp guest_chat_enabled?(%{assigns: %{room: room}}) do
    case check_active_stream(room) do
      {:ok, active_stream} -> active_stream.flags["guest_chat_enabled"]
      _ -> false
    end
  end

  defp handle_message_new(
         %{"forward" => %{"id" => forwarded_message_id}},
         %{assigns: %{user: user, room: room}} = socket
       ) do
    case Chat.Messages.forward(forwarded_message_id, %{room: room, user: user}) do
      {:ok, %Chat.Message{} = message} ->
        broadcast_from!(
          socket,
          "message:new",
          Web.MessageView.render("message.json", %{message: message, user: user})
        )

        {:reply, {:ok, Web.MessageView.render("created_message.json", %{message: message})},
         socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        # TODO move to error helpers?
        {:reply, {:error, BillBored.Helpers.humanize_errors(changeset)}, socket}

      {:error, :not_found} ->
        {:reply, {:error, %{"forwarded_message" => ["does not exist"]}}, socket}
    end
  end

  defp handle_message_new(
         %{"reply_to" => %{"id" => replied_to_message_id}} = attrs,
         %{assigns: %{user: user, room: room}} = socket
       ) do
    case Chat.Messages.reply(attrs, %{to: replied_to_message_id, room: room, user: user}) do
      {:ok, %Chat.Message{} = message} ->
        broadcast_from!(
          socket,
          "message:new",
          Web.MessageView.render("message.json", %{message: message, user: user})
        )

        {:reply, {:ok, Web.MessageView.render("created_message.json", %{message: message})},
         socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:reply, {:error, BillBored.Helpers.humanize_errors(changeset)}, socket}
    end
  end

  defp handle_message_new(params, %{assigns: %{user: user, room: room}} = socket) do
    case Chat.Messages.create(params, %{room: room, user: user}) do
      {:ok, %Chat.Message{} = message} ->
        broadcast_from!(
          socket,
          "message:new",
          Web.MessageView.render("message.json", %{message: message, user: user})
        )

        {:reply, {:ok, Web.MessageView.render("created_message.json", %{message: message})},
         socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        # TODO move to error helpers?
        {:reply, {:error, BillBored.Helpers.humanize_errors(changeset)}, socket}
    end
  end

  # @spec within?(%BillBored.Geo.Point{}, Chat.Room.t()) :: boolean
  # defp within?(user_location, %Chat.Room{
  #        location: dropchat_location,
  #        reach_area_radius: reach_area_radius
  #      }) do
  #   BillBored.Geo.within?(
  #     user_location,
  #     dropchat_location,
  #     Decimal.to_float(reach_area_radius) * 1000
  #   )
  # end

  # TODO very naive approach, optimize
  intercept([
    "privilege:granted",
    "message:new",
    "stream:started",
    "stream:finished",
    "stream:speaker_added",
    "stream:speaker_removed",
    "stream:updated"
  ])

  @impl true
  def handle_out(
        "privilege:granted",
        %{user_id: user_id},
        %Phoenix.Socket{assigns: %{user: %{id: user_id}}} = socket
      ) do
    push(socket, "privilege:granted", %{})
    {:noreply, socket}
  end

  def handle_out("privilege:granted", _payload, socket) do
    {:noreply, socket}
  end

  def handle_out(
        "message:new" = event,
        %{user: %User{id: sender_user_id}} = payload,
        %{assigns: %{ignore_set: ignore_set}} = socket
      ) do
    if MapSet.member?(ignore_set, sender_user_id) do
      {:noreply, socket}
    else
      push(socket, event, payload)
      {:noreply, socket}
    end
  end

  def handle_out("message:new" = event, payload, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  def handle_out(
        event,
        %{updated_dropchat: updated_dropchat, rendered_stream: rendered_stream},
        socket
      )
      when event in ~w(stream:started stream:finished stream:speaker_added stream:speaker_removed) do
    new_socket =
      socket
      |> maybe_handle_finished_stream()
      |> assign(:room, updated_dropchat)

    push(new_socket, event, rendered_stream)
    {:noreply, new_socket}
  end

  def handle_out(
        "stream:updated" = event,
        %{
          event_type: event_type,
          updated_dropchat: updated_dropchat,
          rendered_stream: rendered_stream
        },
        socket
      ) do
    new_socket =
      socket
      |> maybe_handle_finished_stream()
      |> assign(:room, updated_dropchat)

    push(new_socket, event, %{"stream" => rendered_stream, "event_type" => event_type})
    {:noreply, new_socket}
  end

  defp stream_event(%{assigns: %{room: room}} = socket, event, type, updated_stream \\ nil) do
    {:ok, updated_dropchat} =
      case updated_stream do
        %{status: "active"} ->
          {:ok, %Chat.Room{room | active_stream: updated_stream}}

        _ ->
          get_dropchat(room.key)
      end

    new_socket = assign(socket, :room, updated_dropchat)

    rendered_stream =
      if updated_dropchat.active_stream do
        Web.RoomView.render("dropchat_stream.json", %{
          room: updated_dropchat,
          dropchat_stream: updated_dropchat.active_stream
        })
      else
        updated_stream = Repo.get!(DropchatStream, room.active_stream.id)

        Web.RoomView.render("dropchat_stream.json", %{
          room: updated_dropchat,
          dropchat_stream: updated_stream
        })
      end

    payload = %{
      event_type: type,
      updated_dropchat: updated_dropchat,
      rendered_stream: rendered_stream
    }

    Web.Endpoint.broadcast("dropchats:#{room.key}", event, payload)

    {new_socket, payload}
  end

  defp maybe_leave_audience(
         %{assigns: %{user: user, audience_stream: %DropchatStream{} = stream}} = socket
       ) do
    service(DropchatStreams).remove_live_audience_member(stream, user.id)

    socket
    |> assign(:audience_stream, false)
    |> stop_audience_timer()
  end

  defp maybe_leave_audience(socket), do: stop_audience_timer(socket)

  defp maybe_assign_ignore_set(%{assigns: %{user: user}} = socket) do
    blockers_ids = BillBored.User.Blocks.get_blockers_of(user) |> Enum.map(& &1.id)
    blocked_ids = BillBored.User.Blocks.get_blocked_by(user) |> Enum.map(& &1.id)

    ignore_set = MapSet.new(blocked_ids ++ blockers_ids)

    case MapSet.size(ignore_set) do
      0 ->
        %{socket | assigns: Map.delete(socket.assigns, :ignore_set)}

      _ ->
        assign(socket, :ignore_set, ignore_set)
    end
  end

  defp maybe_handle_finished_stream(%{assigns: %{room: room}} = socket) do
    case check_active_stream(room) do
      {:ok, _} ->
        if user_is_speaker?(socket) do
          socket
        else
          stop_streaming_time(socket)
        end

      _ ->
        {:ok, _ref, new_socket} =
          socket
          |> maybe_leave_audience()
          |> stop_streaming_time()
          |> update_presence(%{hand_raised: false})

        new_socket
    end
  end

  defp update_presence(%{assigns: %{user: user}} = socket, map) do
    {:ok, ref} =
      Web.Presence.update(socket, user.id, fn presence ->
        Map.merge(presence, map)
      end)

    new_socket = assign(socket, :presence, Map.merge(socket.assigns[:presence] || %{}, map))
    {:ok, ref, new_socket}
  end
end
