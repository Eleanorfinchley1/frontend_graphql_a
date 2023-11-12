defmodule BillBored.Chat.Messages do
  alias BillBored.{Chat, User, Users, Interest, Hashtag}
  alias Ecto.Multi
  import Ecto.Query

  @doc """
  Creates a new message and updates :last_interaction on the chat room.
  """
  def create(attrs, room_id: room_id, user_id: user_id) do
    create(attrs, %{room: Repo.get!(Chat.Room, room_id), user: Repo.get!(User, user_id)})
  end

  def create(attrs, %{room: %Chat.Room{} = room, user: %User{} = user} = opts) do
    %Chat.Message{room_id: room.id, user_id: user.id}
    |> Chat.Message.changeset(attrs)
    |> do_create(Map.put(opts, :attrs, attrs))
  end

  defp do_create(changeset, %{room: %Chat.Room{} = room} = opts) do
    Multi.new()
    |> Multi.insert(:message, changeset)
    |> maybe_lookup_or_insert_hashtags(changeset)
    |> Multi.update_all(:last_interaction, last_interaction_update(room.id), [])
    |> preloads_multi()
    |> notifications_multi(opts)
    |> Repo.transaction()
    |> case do
      {:ok, %{message_with_preloads: message}} -> {:ok, message}
      {:error, :message, %Ecto.Changeset{} = changeset, _changes} -> {:error, changeset}
    end
  end

  # TODO simplify
  defp notifications_multi(multi, %{room: room, user: user} = opts) do
    Multi.run(multi, :notifications, fn repo, %{message_with_preloads: message} ->
      cond do
        opts[:forwarded_message?] ->
          receivers = Chat.Rooms.list_members_for_apns_notifications(room.id, user.id)

          Notifications.process_chat_message(
            sender: user,
            message: message,
            room: room,
            receivers: receivers
          )

        opts[:reply_message?] ->
          %{to: message_id} = opts

          %Chat.Message{user: %User{id: replied_to_message_author_id}} =
            replied_to_message =
            Chat.Message |> repo.get!(message_id) |> repo.preload(user: :devices)

          Notifications.process_chat_reply(
            sender: user,
            replied_to_message: replied_to_message,
            reply: message,
            room: room,
            muted?: Chat.Rooms.muted?(%{room_id: room.id, user_id: replied_to_message_author_id})
          )

          receivers = Chat.Rooms.list_members_for_apns_notifications(room.id, user.id)
          receivers = Enum.reject(receivers, &(&1.id == replied_to_message_author_id))

          Notifications.process_chat_message(
            sender: user,
            message: message,
            room: room,
            receivers: receivers
          )

        true ->
          %{attrs: attrs} = opts

          usertag_notification_receivers =
            if String.contains?(room.chat_type || "", "group") and not room.private do
              case attrs do
                %{"usertags" => [_ | _] = usertags} ->
                  usertag_notification_receivers(usertags, room.id, user.id)

                _other ->
                  []
              end
            else
              []
            end

          Notifications.process_chat_tagged(
            tagger: user,
            message: message,
            room: room,
            receivers: usertag_notification_receivers
          )

          usertag_notification_receiver_ids =
            Enum.map(usertag_notification_receivers, & &1.user.id)

          receivers = Chat.Rooms.list_members_for_apns_notifications(room.id, user.id)

          receivers =
            Enum.reject(receivers, fn %{id: id} -> id in usertag_notification_receiver_ids end)

          Notifications.process_chat_message(
            sender: user,
            message: message,
            room: room,
            receivers: receivers
          )
      end

      if room.location do
        if messages_count(room.id) >= 1000 do
          unless popular_notified?(room.id) do
            receivers = Users.list_users_located_around_location(room.location)
            Notifications.process_popular_dropchat(roon: room, receivers: receivers)
            mark_popular_notified(room.id)
          end
        end
      end

      {:ok, nil}
    end)
  end

  defp messages_count(room_id) do
    Chat.Message |> where(room_id: ^room_id) |> select([r], count(r.id)) |> Repo.one!()
  end

  defp popular_notified?(room_id) do
    Chat.Room |> where(id: ^room_id) |> select([r], r.popular_notified?) |> Repo.one!()
  end

  defp mark_popular_notified(room_id) do
    Chat.Room |> where(id: ^room_id) |> Repo.update_all(set: [popular_notified?: true])
  end

  # TODO test, test when muted
  @spec usertag_notification_receivers([map], pos_integer, pos_integer) :: [
          %Chat.Room.Membership{}
        ]
  defp usertag_notification_receivers(usertags, room_id, author_id) do
    tagged_user_ids =
      usertags
      |> Enum.map(fn %{"id" => tagged_user_id} -> tagged_user_id end)
      |> Enum.uniq()
      |> Enum.reject(fn user_id -> user_id == author_id end)

    Chat.Room.Membership
    |> where(room_id: ^room_id)
    |> where([ru], ru.userprofile_id in ^tagged_user_ids)
    |> preload([ru], user: :devices)
    |> Repo.all()
  end

  defp preloads_multi(multi) do
    Multi.run(multi, :message_with_preloads, fn _repo, %{message: message} ->
      {:ok, Repo.preload(message, [:media_files, private_post: :media_files])}
    end)
  end

  @spec last_interaction_update(pos_integer) :: Ecto.Query.t()
  defp last_interaction_update(room_id) do
    Chat.Room
    |> where(id: ^room_id)
    |> update(set: [last_interaction: fragment("now()")])
  end

  @spec maybe_lookup_or_insert_hashtags(Multi.t(), Ecto.Changeset.t()) :: Multi.t()
  defp maybe_lookup_or_insert_hashtags(multi, changeset) do
    Multi.run(multi, :hashtags, fn repo, %{message: %Chat.Message{id: message_id}} ->
      case changeset.changes.supplied_hashtags do
        [] ->
          {:ok, []}

        hashtags ->
          # find existing interest hashtags
          interests =
            Interest
            |> where([i], i.hashtag in ^hashtags)
            |> repo.all()

          # save message <-> interests relationships
          repo.insert_all(
            Chat.Message.Interest,
            Enum.map(interests, fn interest ->
              [interest_id: interest.id, message_id: message_id]
            end)
          )

          interest_hashtags =
            Enum.map(interests, fn interest ->
              interest.hashtag
            end)

          # remove interest hashtags
          hashtags =
            Enum.reject(hashtags, fn hashtag ->
              hashtag in interest_hashtags
            end)

          # TODO do it in one request
          # insert or lookup existing custom hashtags
          {_rows_affected, hashtag_ids} =
            repo.insert_all(
              Hashtag,
              Enum.map(hashtags, fn hashtag ->
                dt = NaiveDateTime.utc_now()

                [
                  value: hashtag,
                  inserted_at: dt,
                  updated_at: dt
                ]
              end),
              on_conflict: {:replace, [:updated_at]},
              conflict_target: :value,
              returning: [:id]
            )

          hashtag_ids = Enum.map(hashtag_ids, fn %{id: id} -> id end)

          # save message <-> custom hashtag relationships
          repo.insert_all(
            Chat.Message.Hashtag,
            Enum.map(hashtag_ids, fn hashtag_id ->
              [
                hashtag_id: hashtag_id,
                message_id: message_id,
                inserted_at: NaiveDateTime.utc_now()
              ]
            end)
          )

          {:ok, []}
      end
    end)
  end

  # TODO refactor
  def forward(
        forwarded_message_id,
        %{room: %Chat.Room{id: room_id}, user: %User{id: user_id}} = opts
      ) do
    # TODO authorize forwarding

    Multi.new()
    |> Multi.run(:forwarded_message, fn repo, _changes ->
      case repo.get(Chat.Message, forwarded_message_id) do
        nil -> {:error, :not_found}
        %Chat.Message{} = message -> {:ok, message}
      end
    end)
    |> Multi.run(:copy, fn _repo,
                           %{
                             forwarded_message:
                               %Chat.Message{
                                 id: forwarded_message_id
                               } = forwarded_message
                           } ->
      attrs = Map.from_struct(forwarded_message)

      %Chat.Message{
        room_id: room_id,
        user_id: user_id,
        forwarded_message_id: forwarded_message_id
      }
      |> Chat.Message.changeset(attrs)
      |> do_create(Map.put(opts, :forwarded_message?, true))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{copy: copy}} -> {:ok, copy}
      {:error, :forwarded_message, :not_found, _changes} -> {:error, :not_found}
      {:error, :copy, %Ecto.Changeset{} = changeset, _changes} -> {:error, changeset}
    end
  end

  # TODO test
  def reply(
        attrs,
        %{to: message_id, room: %Chat.Room{id: room_id}, user: %User{id: user_id}} = opts
      ) do
    # TODO authorize reply
    %Chat.Message{room_id: room_id, user_id: user_id, parent_id: message_id}
    |> Chat.Message.changeset(attrs)
    |> do_create(Map.put(opts, :reply_message?, true))
  end

  # TODO test
  @spec fetch(pos_integer, :after | :before, pos_integer, map()) :: [Chat.Message.t()]
  def fetch(room_id, position, message_id, %{order: order} = params) do
    query =
      from(m in Chat.Message.available(params),
        where: m.room_id == ^room_id
      )

    query =
      case position do
        :after -> where(query, [m], m.id > ^message_id)
        :before -> where(query, [m], m.id < ^message_id)
      end

    # TODO maybe use transaction to checkout a single connection
    query
    |> order_by([m], [{^order, m.id}])
    |> preload([:user, :media_files, private_post: :media_files])
    |> Repo.all()
  end

  # TODO refactor
  @spec fetch(pos_integer, :after | :before, pos_integer, map()) :: [Chat.Message.t()]
  def fetch(room_id, position, message_id, %{limit: limit, order: order} = params) do
    query =
      from(m in Chat.Message.available(params),
        where: m.room_id == ^room_id
      )

    query =
      case position do
        :after -> where(query, [m], m.id > ^message_id)
        :before -> where(query, [m], m.id < ^message_id)
      end

    query
    |> order_by([m], [{^order, m.id}])
    |> limit(^limit)
    |> preload([:user, :media_files, private_post: :media_files])
    |> Repo.all()
  end

  @spec author_id(pos_integer) :: pos_integer | nil
  def author_id(message_id) do
    Chat.Message
    |> where(id: ^message_id)
    |> select([m], m.user_id)
    |> Repo.one()
  end

  @spec author(pos_integer) :: User.t() | nil
  def author(message_id) do
    Chat.Message
    |> where(id: ^message_id)
    |> join(:left, [m], u in User, on: u.id == m.user_id)
    |> select([m, u], u)
    |> Repo.one()
  end

  @spec mark_read(Chat.Room.t(), User.t()) :: {updated_rows_count :: integer, nil}
  def mark_read(%Chat.Room{id: room_id}, %User{id: user_id}) do
    BillBored.Chat.Message
    |> where(room_id: ^room_id)
    |> where([m], m.user_id != ^user_id)
    |> update([m], set: [is_seen: true])
    |> Repo.update_all([])
  end

  # used only for tests (both in rdb and in web (chat_channel_test)) for now
  if Mix.env() == :test do
    @spec get_by(Keyword.t()) :: Chat.Message.t() | nil
    def get_by(constraints) do
      Repo.get_by(Chat.Message, constraints)
    end
  end
end
