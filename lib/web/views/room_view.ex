defmodule Web.RoomView do
  use Web, :view
  alias BillBored.{Chat, User}

  def render("index.json", %{rooms: rooms}) do
    %{rooms: render_many(rooms, __MODULE__, "dropchat.json")}
  end

  # TODO test and refactor
  def render("room.json", %{
        room:
          %Chat.Room{
            id: room_id,
            key: key,
            members: members,
            administrators: administrators,
            title: title,
            location: location,
            private: private?,
            last_interaction: last_interaction,
            created: created,
            chat_type: chat_type,
            last_message: last_message,
            ghost_allowed: ghost_allowed,
            color: color
          } = room
      }) do
    members =
      Enum.map(members, fn %User{} = user ->
        Web.UserView.render("user.json", %{user: user})
      end)

    administrators =
      Enum.map(administrators, fn %User{} = user ->
        Web.UserView.render("user.json", %{user: user})
      end)

    shared_chat_info = %{
      "id" => room_id,
      "key" => key,
      "users" => members,
      "administrators" => administrators,
      "title" => title,
      "ghost_allowed" => ghost_allowed,
      "location" => render_one(location, Web.LocationView, "show.json"),
      "private" => private?,
      "last_interaction" => last_interaction,
      "color" => color,
      "last_message" => last_message,
      "created" => created,
      "chat_type" => chat_type
    }

    # TODO refactor
    case chat_type do
      # TODO currently these are stored as "dropchat"
      # would be nice to have an enum type for chat type
      "drop" <> _ ->
        %{color: color, place: place} = room

        rendered_place =
          if place do
            Web.PlaceView.render("show.json", %{place: place})
          end

        shared_chat_info
        |> Map.put("place", rendered_place)
        |> Map.put("color", color)

      _other ->
        shared_chat_info
    end
  end

  # TODO need it?
  def render("dropchat.json", %{room: room}) do
    %Chat.Room{
      id: id,
      key: key,
      private: private?,
      location: location,
      members: members,
      moderators: moderators,
      administrators: administrators,
      title: title,
      chat_type: chat_type,
      created: created,
      messages_count: messages_count,
      color: color,
      place: place,
      reactions_count: reactions_count,
      last_message: last_message,
      ghost_allowed: ghost_allowed,
      university: university,
      is_access_required: is_access_required
    } = room

    rendered_place =
      if place do
        Web.PlaceView.render("show.json", %{place: place})
      end

    members =
      if Ecto.assoc_loaded?(members) do
        Enum.map(members, fn %User{} = user ->
          Web.UserView.render("user.json", %{user: user})
        end)
      end

    moderators =
      if Ecto.assoc_loaded?(moderators) do
        Enum.map(moderators, fn %User{} = user ->
          Web.UserView.render("user.json", %{user: user})
        end)
      end

    administrators =
      if Ecto.assoc_loaded?(administrators) do
        if(is_map(administrators), do: [administrators], else: administrators)
        |> Enum.map(fn %User{} = user ->
          Web.UserView.render("user.json", %{user: user})
        end)
      end

    active_stream =
      if Ecto.assoc_loaded?(room.active_stream) && room.active_stream do
        render("dropchat_stream.json", %{room: room, dropchat_stream: room.active_stream})
      end

    # TODO render rigths

    payload = %{
      "id" => id,
      "key" => key,
      "title" => title,
      "private" => private?,
      "created" => created,
      "chat_type" => chat_type,
      "location" => render_one(location, Web.LocationView, "show.json"),
      "messages_count" => messages_count,
      "color" => color,
      "place" => rendered_place,
      "is_access_required" => is_access_required,
      "users" => members,
      "moderators" => moderators,
      "administrators" => administrators,
      "active_stream" => active_stream,
      "ghost_allowed" => ghost_allowed,
      "last_message" => last_message,
      "reactions_count" => reactions_count
    }

    if not is_nil(university) do
      Map.put(payload, "university", university)
    else
      payload
    end
  end

  @default_reactions_count %{"like" => 0, "dislike" => 0, "clapping" => 0}

  def render("dropchat_stream.json", %{room: room, dropchat_stream: stream}) do
    admin =
      if Ecto.assoc_loaded?(stream.admin) do
        Web.UserView.render("user.json", %{user: stream.admin})
      end

    speakers =
      if Ecto.assoc_loaded?(stream.speakers) do
        Enum.map(stream.speakers, fn %User{} = user ->
          Web.UserView.render("user.json", %{user: user})
        end)
      else
        []
      end

    result =
      %{
        "id" => stream.id,
        "channel_name" => "#{room.key}:#{stream.key}",
        "title" => stream.title,
        "status" => stream.status,
        "inserted_at" => stream.inserted_at,
        "admin" => admin,
        "speakers" => speakers,
        "reactions_count" => if stream.reactions_count do
          Map.merge(@default_reactions_count, stream.reactions_count)
        else
          @default_reactions_count
        end,
        "live_audience_count" => stream.live_audience_count,
        "peak_audience_count" => stream.peak_audience_count,
        "flags" => stream.flags,
        "recording" => if stream.recording_data do
          render("dropchat_stream_recording.json", %{recording_data: stream.recording_data})
        else
          nil
        end
      }

    if stream.user_reactions do
      Map.put(result, "user_reactions", stream.user_reactions)
    else
      result
    end
  end

  def render("dropchat_stream_recording.json", %{recording_data: recording_data}) do
    if recording_data.status in ["started", "in_progress", "finished"] do
      %{
        status: recording_data.status,
        urls: if recording_data.files do
          Enum.flat_map(recording_data.files, fn
            %{"fileName" => filename} -> [BillBored.Agora.API.public_url(filename)]
            _ -> []
          end)
        else
          []
        end
      }
    else
      %{
        status: recording_data.status,
        urls: []
      }
    end
  end

  def render("chat_members.json", %{members: members}) do
    %{
      members: render_many(members, __MODULE__, "chat_member.json", as: :member)
    }
  end

  def render("chat_member.json", %{member: %{privileges: privileges, role: role} = member}) do
    Web.UserView.render("min.json", %{user: member})
    |> Map.put(:privileges, privileges)
    |> Map.put(:role, role)
  end
end
