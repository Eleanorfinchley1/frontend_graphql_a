defmodule BillBored.Chat.Rooms do
  alias BillBored.{Chat, User, Place}
  import BillBored.Geo, only: [fake_place: 1]
  import Ecto.Query

  alias BillBored.User
  alias BillBored.University
  alias BillBored.Chat.Room.Membership, as: RoomMembership
  alias BillBored.Chat.Room.Administratorship, as: RoomAdministratorship
  alias BillBored.Chat.Room.ElevatedPrivilege
  alias BillBored.Chat.Room.DropchatBan
  alias BillBored.Chat.Room.DropchatStream

  @spec get(pos_integer | String.t()) :: Chat.Room.t() | nil
  def get(room_id) do
    Repo.get(Chat.Room, room_id)
  end

  @spec get!(pos_integer | String.t()) :: Chat.Room.t()
  def get!(room_id) do
    Repo.get!(Chat.Room, room_id)
  end

  def get_by(opts) do
    Repo.get_by(Chat.Room, opts)
  end

  def get_by!(opts) do
    Repo.get_by!(Chat.Room, opts)
  end

  @spec preload_room(Chat.Room.t(), [atom | Keyword.t()]) :: Chat.Room.t()
  def preload_room(room, fields) do
    Repo.preload(room, fields)
  end

  def delete(%_{id: room_id} = room) do
    from(a in Chat.Room.Administratorship, where: a.room_id == ^room_id)
    |> Repo.delete_all()

    from(m in Chat.Room.Membership, where: m.room_id == ^room_id)
    |> Repo.delete_all()

    from(i in Chat.Room.Interestship, where: i.room_id == ^room_id)
    |> Repo.delete_all()

    from(i in Chat.Room.ElevatedPrivilege.Request, where: i.room_id == ^room_id)
    |> Repo.delete_all()

    Repo.delete(room)
  end

  def create(admin_or_id, attrs, opts \\ [])

  def create(%User{id: admin_user_id}, attrs, opts) do
    create(admin_user_id, attrs, opts)
  end

  def create(admin_user_id, attrs, opts) do
    attrs = add_dropchat_safe_location(attrs)

    add_members = Keyword.get(opts, :add_members, [])
    member_ids = Enum.uniq([admin_user_id | add_members])

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:validate_members, fn _, _ ->
        with :ok <- validate_chat_type_members(attrs[:chat_type], member_ids) do
          {:ok, :ok}
        end
      end)
      |> Ecto.Multi.run(:insert_room, fn _, _ ->
        Repo.insert(Chat.Room.changeset(%Chat.Room{}, attrs))
      end)
      |> Ecto.Multi.run(:insert_members, fn _, %{insert_room: room} ->
        Enum.reduce_while(member_ids, {:ok, []}, fn member_id, {:ok, added_membersips} ->
          with {:ok, added_membership} <- Chat.Room.Memberships.create(member_id, room.id, "member") do
            {:cont, {:ok, [added_membership | added_membersips]}}
          else
            error ->
              {:halt, error}
          end
        end)
      end)
      |> Ecto.Multi.run(:insert_admin, fn _, %{insert_room: room} ->
        role = if room.chat_type == "one-to-one", do: "member", else: "administrator"

        with {:ok, _admin_membership} <- Chat.Room.Memberships.create(admin_user_id, room.id, role),
             {:ok, administratorship} <- Repo.insert(%Chat.Room.Administratorship{userprofile_id: admin_user_id, room_id: room.id}) do
          {:ok, administratorship}
        end
      end)
      |> Repo.transaction()


    with {:ok, %{insert_room: room}} <- result do
      {:ok, room}
    else
      {:error, :validate_members, %{duplicated_chat: room}, %{}} ->
        {:error, %{duplicated_chat: room}}
      error -> error
    end
  end

  defp validate_chat_type_members("one-to-one", [member1_id, member2_id]) do
    query =
      from(r in Chat.Room,
        join: m1 in Chat.Room.Membership,
        on: m1.room_id == r.id,
        join: m2 in Chat.Room.Membership,
        on: m2.room_id == r.id,
        where:
          r.chat_type == "one-to-one" and
          (
            (m1.userprofile_id == ^member1_id and m2.userprofile_id == ^member2_id) or
            (m1.userprofile_id == ^member2_id and m2.userprofile_id == ^member1_id)
          ),
        limit: 1
      )

    case Repo.exists?(query) do
      false -> :ok
      true -> {:error, %{duplicated_chat: Repo.one(query)}}
    end
  end

  defp validate_chat_type_members("one-to-one", _), do: {:error, :must_have_two_members}

  defp validate_chat_type_members(_, _), do: :ok

  def get_available_rooms(user_id) do
    Chat.Room
    |> join(:left, [r], m in assoc(r, :participants))
    |> where([r, m], m.id == ^user_id)
    |> Ecto.Query.preload([
      :members,
      :moderators,
      :administrators,
      :interests,
      :interest,
      :pending,
      :place
    ])
  end

  @spec last_message(pos_integer) :: Chat.Message.t() | nil
  def last_message(room_id) do
    Chat.Message
    |> where(room_id: ^room_id)
    |> order_by([m], desc: m.id)
    |> limit(1)
    |> select([m], map(m, [:id, :message, :message_type, :user_id]))
    |> preload([:media_files])
    |> Repo.one()
  end

  defmacrop last_messages(room_id) do
    # TODO preload media files?
    quote do
      fragment(
        "SELECT cm.* FROM chat_message AS cm WHERE cm.room_id = ? ORDER BY cm.id DESC LIMIT 1",
        unquote(room_id)
      )
    end
  end

  # TODO Refactor
  @spec list(for: User.t()) :: [Chat.Room.t()]
  def list(for: %User{id: user_id}) do
    rooms_with_last_messages =
      Chat.Room
      |> preload([:members, :moderators, :administrators, :place])
      |> join(:inner, [r], m in Chat.Room.Membership, on: m.room_id == r.id)
      |> where([r, m], m.userprofile_id == ^user_id)
      |> join(:left_lateral, [r, _m], last_message in last_messages(r.id))
      |> order_by([r, _m, _last_message], desc: r.last_interaction)
      # TODO consider last_message being a pointer to the messages table and then update it just like  last_interaction
      |> select(
        [r, _m, last_message],
        {r,
         %{
           id: last_message.id,
           message: last_message.message,
           message_type: last_message.message_type,
           user_id: last_message.user_id
         }}
      )
      |> Repo.all()

    all_last_message_ids =
      rooms_with_last_messages
      |> Enum.map(fn {_room, maybe_last_message} -> get_in(maybe_last_message, [:id]) end)
      |> Enum.uniq()

    last_message_to_media_file_keys =
      "message_uploads"
      |> where([u], u.message_id in ^all_last_message_ids)
      |> select([u], {u.message_id, u.upload_key})
      |> Repo.all()
      |> Enum.group_by(
        fn {message_id, _upload_key} -> message_id end,
        fn {_message_id, upload_key} -> upload_key end
      )

    Enum.map(rooms_with_last_messages, fn {room, last_message} ->
      if last_message_id = last_message.id do
        last_message =
          Map.put(
            last_message,
            :media_file_keys,
            last_message_to_media_file_keys[last_message_id] || []
          )

        %{room | last_message: last_message}
      else
        room
      end
    end)
  end

  # TODO Refactor
  def list(for: user_id, chat_types: types) do
    rooms_with_last_messages =
      Chat.Room
      |> preload([:members, :moderators, :administrators, :place, :interests, :pending])
      |> join(:inner, [r], m in Chat.Room.Membership, on: m.room_id == r.id)
      |> where([r, m], m.userprofile_id == ^user_id and r.chat_type in ^types)
      |> join(:left_lateral, [r, _m], last_message in last_messages(r.id))
      |> order_by([r, _m, _last_message], desc: r.last_interaction)
      # TODO consider last_message being a pointer to the messages table and then update it just like  last_interaction
      |> select(
        [r, _m, last_message],
        {r,
         %{
           id: last_message.id,
           message: last_message.message,
           message_type: last_message.message_type,
           user_id: last_message.user_id
         }}
      )
      |> Repo.all()

    all_last_message_ids =
      rooms_with_last_messages
      |> Enum.map(fn {_room, maybe_last_message} -> get_in(maybe_last_message, [:id]) end)
      |> Enum.uniq()

    last_message_to_media_file_keys =
      "message_uploads"
      |> where([u], u.message_id in ^all_last_message_ids)
      |> select([u], {u.message_id, u.upload_key})
      |> Repo.all()
      |> Enum.group_by(
        fn {message_id, _upload_key} -> message_id end,
        fn {_message_id, upload_key} -> upload_key end
      )

    Enum.map(rooms_with_last_messages, fn {room, last_message} ->
      if last_message_id = last_message.id do
        last_message =
          Map.put(
            last_message,
            :media_file_keys,
            last_message_to_media_file_keys[last_message_id] || []
          )

        %{room | last_message: last_message}
      else
        room
      end
    end)
  end

  # TODO refactor
  @spec list_administrators(pos_integer | String.t()) :: [User.t()]
  def list_administrators(room_id) do
    Chat.Room
    |> where(id: ^room_id)
    |> join(
      :inner,
      [room],
      room_admin in Chat.Room.Administratorship,
      on: room.id == room_admin.room_id
    )
    |> join(:inner, [room, room_admin], admin in User, on: room_admin.userprofile_id == admin.id)
    |> select([room, room_admin, admin], admin)
    |> Repo.all()
  end

  defmacrop last_day(created) do
    quote do
      fragment("? > (now() + '-1 day')::timestamp", unquote(created))
    end
  end

  @spec dropchat_query() :: Ecto.Query.t()
  defp dropchat_query() do
    Chat.Room
    |> where([r], last_day(r.last_interaction))
    |> where([r], r.private == false)
    |> join(:left, [r], m in Chat.Message, on: r.id == m.room_id)
    |> join(:left, [r, m], p in Place, on: r.place_id == p.id)
    |> group_by([r, m, p], [r.id, p.id])
    |> select([r, m, p], %{r | messages_count: count(m.id), place: p})
  end

  @spec list_dropchats_by_location(%BillBored.Geo.Polygon{}) :: [Chat.Room.t()]
  def list_dropchats_by_location(%BillBored.Geo.Polygon{} = polygon) do
    import Geo.PostGIS, only: [st_covered_by: 2]

    dropchat_query()
    |> where([r], st_covered_by(r.location, ^polygon))
    |> Repo.all()
  end

  @spec list_dropchats_by_location(%BillBored.Geo.Point{}, pos_integer) :: [Chat.Room.t()]
  def list_dropchats_by_location(%BillBored.Geo.Point{} = point, radius_in_m) do
    import Geo.PostGIS, only: [st_dwithin_in_meters: 3]

    dropchat_query()
    |> where([r], st_dwithin_in_meters(r.location, ^point, ^radius_in_m))
    |> Repo.all()
  end

  # @doc """
  # Return query of rooms with the last_message association and last_message virtual field
  # e.g) queryable_rooms_with_last_message(Chat.Room)
  # """
  defp queryable_rooms_with_last_message(queryable) do
    queryable
    |> join(:left_lateral, [r], lm in last_messages(r.id), as: :last_message)
    |> select_merge([r, last_message: lm], %{
      last_message: fragment("json_build_object(?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        "id", lm.id, "message", lm.message, "message_type", lm.message_type, "user_id", lm.user_id, "created", lm.created
      ),
    })
  end

  # @doc """
  # Return query of rooms with the row_num specified the row number sorted by created
  # e.g) queryable_rooms_with_numbered_by_created(Chat.Room)
  # """
  defp queryable_rooms_with_numbered_by_created(queryable) do
    queryable
    |> select_merge([r], %{
      row_num: fragment("ROW_NUMBER() OVER(ORDER BY ? DESC)", r.created)
    })
  end

  # @doc """
  # Return query of rooms with reaction_counts virtual field
  # e.g) queryable_rooms_with_reaction_counts(Chat.Room)
  # """
  defp queryable_rooms_with_reaction_counts(queryable) do
    queryable
    |> join(:left, [r], streams in assoc(r, :streams), as: :streams)
    |> group_by([r, last_message: lm], [r.id, lm.id, lm.message, lm.message_type, lm.user_id, lm.created])
    |> select_merge([r, streams: streams], %{
      reactions_count: fragment("json_build_object('like', sum(COALESCE((?->>'like')::integer, 0)), 'dislike', sum(COALESCE((?->>'dislike')::integer, 0)), 'clapping', sum(COALESCE((?->>'clapping')::integer, 0)))",
        streams.reactions_count, streams.reactions_count, streams.reactions_count
      )
    })
  end

  defp queryable_rooms_with_is_recent(queryable) do
    now = DateTime.utc_now()
    ago_24_hours = DateTime.add(now, - 3600 * 24)
    ago_48_hours = DateTime.add(now, - 3600 * 48)

    queryable
      |> where(private: false)
      |> queryable_rooms_with_last_message
      |> queryable_rooms_with_reaction_counts
      |> select_merge([r, last_message: lm, streams: streams], %{
        is_recent: lm.created > ^ago_24_hours and fragment("MAX(COALESCE(?, ?))", streams.finished_at, ^now) > ^ago_48_hours or r.created > ^ago_48_hours
      })
  end

  defp sort_query_rooms(query, %{point: point} = params) do
    sort_strategies = ["hot topic", "recent"]
    sort_strategies = if not is_nil(point) do
      sort_strategies ++ ["distance"]
    else
      sort_strategies
    end

    sort_query_rooms_by_strategy(query, Enum.random(sort_strategies), params)
  end

  defp sort_query_rooms_by_strategy(
    query,
    "hot topic",
    %{user_id: user_id, university_id: university_id} = _params
  ) do
    query
    |> join(:inner, [r], a in assoc(r, :administrators), as: :admin)
    |> join(:left, [admin: adm], un in University, on: adm.university_id == un.id, as: :university)
    |> join(:left, [r, _m, _d], d in DropchatStream, on: r.id == d.dropchat_id and d.status == "active", as: :active_stream)
    |> order_by([r, admin: ad, active_stream: ats],
      [
        asc: is_nil(ats.id),
        desc: ad.id == ^user_id,
        desc: ad.university_id == ^university_id,
        desc: fragment("COALESCE((?->>'like')::integer + (?->>'clapping')::integer, 0)", r.reactions_count, r.reactions_count)
      ]
    )
  end

  defp sort_query_rooms_by_strategy(
    query,
    "distance",
    %{user_id: user_id, university_id: university_id, point: point} = _params
  ) do
    import Geo.PostGIS, only: [st_distance_in_meters: 2]

    query
    |> join(:inner, [r], a in assoc(r, :administrators), as: :admin)
    |> join(:left, [admin: adm], un in University, on: adm.university_id == un.id, as: :university)
    |> join(:left, [r, _m, _d], d in DropchatStream, on: r.id == d.dropchat_id and d.status == "active", as: :active_stream)
    |> order_by([r, admin: ad, active_stream: ats],
      [
        asc: is_nil(ats.id),
        desc: ad.id == ^user_id,
        desc: ad.university_id == ^university_id,
        asc: st_distance_in_meters(r.location, ^point)
      ]
    )
  end

  defp sort_query_rooms_by_strategy(
    query,
    "recent",
    %{user_id: user_id, university_id: university_id} = _params
  ) do
    query
    |> join(:inner, [r], a in assoc(r, :administrators), as: :admin)
    |> join(:left, [admin: adm], un in University, on: adm.university_id == un.id, as: :university)
    |> join(:left, [r, _m, _d], d in DropchatStream, on: r.id == d.dropchat_id and d.status == "active", as: :active_stream)
    |> order_by([r, admin: ad, active_stream: ats],
      [
        asc: is_nil(ats.id),
        desc: ad.id == ^user_id,
        desc: ad.university_id == ^university_id,
        desc: r.created
      ]
    )
  end

  defp sort_query_rooms_by_strategy(
    query,
    "updated",
    %{} = _params
  ) do
    query
    |> join(:inner, [r], a in assoc(r, :administrators), as: :admin)
    |> join(:left, [admin: adm], un in University, on: adm.university_id == un.id, as: :university)
    |> join(:left, [r, _m, _d], d in DropchatStream, on: r.id == d.dropchat_id and d.status == "active", as: :active_stream)
    |> order_by([r],
      [
        desc: r.last_interaction
      ]
    )
  end

  defp queryable_rooms_by_keyword(queryable, keyword) when is_nil(keyword) or keyword == "", do: queryable

  defp queryable_rooms_by_keyword(queryable, keyword) do
    keyword = "%#{keyword}%"
    queryable |> where(
      [r, admin: adm, active_stream: ats],
      like(r.title, ^keyword) or like(adm.username, ^keyword) or like(ats.title, ^keyword)
    )
  end

  def list_user_sort_dropchats_by_location(%{} = params, %BillBored.Geo.Polygon{} = polygon) do
    import Geo.PostGIS, only: [st_covered_by: 2]

    queryable = Chat.Room
      |> queryable_rooms_with_is_recent
      |> where([r], st_covered_by(r.location, ^polygon))
      |> queryable_rooms_with_numbered_by_created

    # Return query union of the rooms with chats within recent 24 hours or dropchats within recent 48 hours and the 20 rooms created recently.
    subquery(queryable)
    |> where([r], r.is_recent == true or r.row_num <= 20)
    |> sort_query_rooms(Map.put(params, :point, nil))
    |> queryable_rooms_by_keyword(params.keyword)
    |> select_merge([admin: adm, active_stream: ats, university: un],
      %{
        active_stream: ats,
        university: un,
        administrators: adm
      }
    )
    |> Repo.all()
  end

  def list_user_sort_dropchats_by_location(%{} = params, %BillBored.Geo.Point{} = point, radius_in_m) do
    import Geo.PostGIS, only: [st_dwithin_in_meters: 3]

    queryable = Chat.Room
      |> queryable_rooms_with_is_recent
      |> where([r], st_dwithin_in_meters(r.location, ^point, ^radius_in_m))
      |> queryable_rooms_with_numbered_by_created

    # Return query union of the rooms with chats within recent 24 hours or dropchats within recent 48 hours and the 20 rooms created recently.
    subquery(queryable)
    |> where([r], r.is_recent == true or r.row_num <= 20)
    |> sort_query_rooms(Map.put(params, :point, point))
    |> queryable_rooms_by_keyword(params.keyword)
    |> select_merge([admin: adm, active_stream: ats, university: un],
      %{
        active_stream: ats,
        university: un,
        administrators: adm
      }
    )
    |> Repo.all()
  end

  def list_location_dropchats_sorted_by_updated(%{} = params, %BillBored.Geo.Polygon{} = _polygon) do
    # import Geo.PostGIS, only: [st_covered_by: 2]

    queryable = Chat.Room
      |> queryable_rooms_with_is_recent
      # |> where([r], st_covered_by(r.location, ^polygon))
      |> queryable_rooms_with_numbered_by_created

    # Return query union of the rooms with chats within recent 24 hours or dropchats within recent 48 hours and the 20 rooms created recently.
    subquery(queryable)
    |> where([r], r.is_recent == true or r.row_num <= 20)
    |> sort_query_rooms_by_strategy("updated", params)
    |> queryable_rooms_by_keyword(params.keyword)
    |> select_merge([admin: adm, active_stream: ats, university: un],
      %{
        active_stream: ats,
        university: un,
        administrators: adm
      }
    )
    |> Repo.all()
  end

  def list_location_dropchats_sorted_by_updated(%{} = params, %BillBored.Geo.Point{} = _point, _radius_in_m) do
    # import Geo.PostGIS, only: [st_dwithin_in_meters: 3]

    queryable = Chat.Room
      |> queryable_rooms_with_is_recent
      # |> where([r], st_dwithin_in_meters(r.location, ^point, ^radius_in_m))
      |> queryable_rooms_with_numbered_by_created

    # Return query union of the rooms with chats within recent 24 hours or dropchats within recent 48 hours and the 20 rooms created recently.
    subquery(queryable)
    |> where([r], r.is_recent == true or r.row_num <= 20)
    |> sort_query_rooms_by_strategy("updated", params)
    |> queryable_rooms_by_keyword(params.keyword)
    |> select_merge([admin: adm, active_stream: ats, university: un],
      %{
        active_stream: ats,
        university: un,
        administrators: adm
      }
    )
    |> Repo.all()
  end

  @spec get_dropchat(String.t()) :: Chat.Room.t() | nil
  def get_dropchat(room_key) do
    Chat.Room
    |> where(key: ^room_key)
    |> where(private: false)
    |> join(:left, [r], p in Place, on: r.place_id == p.id)
    |> select([r, p], %{r | place: p})
    |> Repo.one()
    |> Repo.preload([:members, :moderators, :administrators, active_stream: [:admin, :speakers]])
  end

  @doc """
  User is in dropchat_elevated_privileges table or an admin for the room.
  """
  @spec priveleged_member?(Chat.Room.t(), User.t()) :: boolean
  def priveleged_member?(%Chat.Room{id: room_id} = room, %User{id: user_id} = user) do
    Chat.Room.ElevatedPrivilege
    |> where(dropchat_id: ^room_id)
    |> where(user_id: ^user_id)
    |> select([ep], count(ep.id))
    |> Repo.one()
    |> case do
      1 ->
        true

      0 ->
        # TODO use UNION
        admin?(room, user)
    end
  end

  @spec admin?(Chat.Room.t(), User.t()) :: boolean
  def admin?(%Chat.Room{id: room_id}, %User{id: user_id}) do
    admin?(room_id: room_id, user_id: user_id)
  end

  # TODO refactor

  @spec admin?(room_id: pos_integer, user_id: pos_integer) :: boolean
  def admin?(room_id: room_id, user_id: user_id) do
    Chat.Room.Administratorship
    |> where(room_id: ^room_id)
    |> where(userprofile_id: ^user_id)
    |> select([a], count(a.id))
    |> Repo.one()
    |> case do
      1 -> true
      0 -> false
    end
  end

  @spec request_write_privelege!(Chat.Room.t(), User.t()) ::
          Chat.Room.ElevatedPrivilege.Request.t()
  def request_write_privelege!(%Chat.Room{id: room_id} = room, %User{id: user_id} = requester) do
    # TODO use multi
    request =
      %Chat.Room.ElevatedPrivilege.Request{room_id: room_id, userprofile_id: user_id}
      |> Repo.insert!()

    request = %{request | room: Repo.preload(room, administrators: :devices), user: requester}

    Notifications.process_dropchat_privilege_request(request)

    request
  end

  @spec get_dropchat_statistics([pos_integer]) :: [map]
  def get_dropchat_statistics([]), do: []

  def get_dropchat_statistics(dropchat_ids) do
    # TODO pass dropchat_ids only once
    # maybe try a lateral join instead of where clauses

    messages_count_subquery =
      Chat.Message
      |> group_by([m], m.room_id)
      |> where([m], m.room_id in ^dropchat_ids)
      |> select([m], %{dropchat_id: m.room_id, count: count(m.id)})

    query =
      Chat.Room
      |> where([r], r.id in ^dropchat_ids)
      |> join(:left, [r], m in subquery(messages_count_subquery), on: r.id == m.dropchat_id)
      |> select([r, m], %{id: r.id, messages_count: m.count})

    Repo.all(query)
  end

  def list_members(room_id) do
    members_query = from(m in RoomMembership, where: m.room_id == ^room_id, select: m.userprofile_id)
    administrators_query = from(a in RoomAdministratorship, where: a.room_id == ^room_id, select: a.userprofile_id)
    privileges_query = from(p in ElevatedPrivilege, where: p.dropchat_id == ^room_id, select: p.user_id)

    member_ids_query = members_query
    |> union(^administrators_query)
    |> union(^privileges_query)

    from(u in User,
      left_join: m in RoomMembership,
      on: m.userprofile_id == u.id and m.room_id == ^room_id,
      left_join: a in RoomAdministratorship,
      on: a.userprofile_id == u.id and a.room_id == ^room_id,
      left_join: p in ElevatedPrivilege,
      on: p.user_id == u.id and p.dropchat_id == ^room_id,
      where:
        u.id in subquery(member_ids_query) and
        (not is_nil(a.id) or (is_nil(a.id) and not is_nil(m.userprofile_id))),
      select_merge: %{
        role: fragment("CASE WHEN ? IS NULL THEN ? ELSE ? END", a.id, m.role, "administrator"),
        privileges: fragment("CASE WHEN ? IS NULL THEN (CASE WHEN ? IS NULL THEN ? ELSE ? END) ELSE ? END",
                             a.id, p.id, ["read"], ["read", "write"], ["read", "write"])
      },
      order_by: [asc: u.username]
    )
    |> Repo.all()
  end

  @spec list_members_for_apns_notifications(pos_integer, pos_integer) :: [User.t()]
  def list_members_for_apns_notifications(room_id, author_id) do
    members =
      "chat_room_users"
      |> where(room_id: ^room_id)
      |> where(muted?: false)
      |> where([ru], ru.userprofile_id != ^author_id)
      |> select([ru], %{id: ru.userprofile_id})

    User
    |> where(enable_push_notifications: true)
    |> join(:inner, [u], m in subquery(members), on: u.id == m.id)
    |> preload([u], :devices)
    |> Repo.all()
  end

  def get_dropchats(user_id, _geometry, count, page) do
    Chat.Room
    |> join(:left, [r], b in DropchatBan, on: b.dropchat_id == r.id and b.banned_user_id == ^user_id)
    |> where([r, b], is_nil(b.id))
    |> where([r], not is_nil(r.location))
    |> where([r], r.private == false)
    |> limit(^count)
    |> offset(^(page * count))
    |> Ecto.Query.preload(:place)
    |> Repo.all()
  end

  def get_all_dropchats(user_id, page, page_size) do
    Chat.Room
    |> join(:left, [r], b in DropchatBan, on: b.dropchat_id == r.id and b.banned_user_id == ^user_id)
    |> join(:left, [r], as in DropchatStream, on: as.dropchat_id == r.id and as.status == "active")
    |> where([r, b], is_nil(b.id))
    |> where([r], not is_nil(r.location))
    |> where([r], r.private == false)
    |> order_by([r, _, as], [fragment("? DESC NULLS LAST", as.last_audience_count), desc: r.created])
    |> limit(^page_size)
    |> offset(^((max(page, 1) - 1) * page_size))
    |> Ecto.Query.preload([:place, :active_stream])
    |> Repo.all()
  end

  def add_dropchat_safe_location(%{chat_type: "dropchat", fake_location?: false} = attrs),
    do: attrs

  def add_dropchat_safe_location(%{chat_type: "dropchat"} = attrs),
    do: do_add_safe_location(attrs)

  def add_dropchat_safe_location(attrs), do: attrs

  defp do_add_safe_location(%{location: %BillBored.Geo.Point{lat: lat, long: lng}} = attrs) do
    %{
      attrs
      | # TODO
        location: fake_location!(lat, lng),
        reach_area_radius: Decimal.add(attrs.reach_area_radius, 2)
    }
  end

  defp fake_location!(lat, lng) do
    # TODO
    {:ok, %BillBored.Place{location: %BillBored.Geo.Point{} = location}} = fake_place({lat, lng})
    location
  end

  def mute_room(%{room_id: room_id, user_id: user_id}) do
    "chat_room_users"
    |> where(room_id: ^room_id)
    |> where(userprofile_id: ^user_id)
    |> Repo.update_all(set: [muted?: true])
  end

  def unmute_room(%{room_id: room_id, user_id: user_id}) do
    "chat_room_users"
    |> where(room_id: ^room_id)
    |> where(userprofile_id: ^user_id)
    |> Repo.update_all(set: [muted?: false])
  end

  def muted?(%{room_id: room_id, user_id: user_id}) do
    "chat_room_users"
    |> where(userprofile_id: ^user_id)
    |> where(room_id: ^room_id)
    |> Repo.exists?()
  end

  def list_muted_room_ids(user_id) do
    "chat_room_users"
    |> where(userprofile_id: ^user_id)
    |> select([:room_id])
    |> Repo.all()
  end
end
