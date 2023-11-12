defmodule BillBored.Chat.Message do
  @moduledoc """
  schema for chat_message table

  see https://gitlab.com/billbored-group/BillBored/tree/master/api#chat-messages for more
  """

  use BillBored, :schema
  use BillBored.User.Blockable, foreign_key: :user_id

  import BillBored.Helpers, only: [media_files_from_keys: 1]
  alias BillBored.{User, Chat, Post, Interest, Upload}

  @type t :: %__MODULE__{}

  schema "chat_message" do
    field(:message, :string)

    # only in 1-to-1 private chats for now
    field(:is_seen, :boolean, default: false)
    field(:location, Geo.PostGIS.Geometry)

    field(:supplied_hashtags, {:array, :string}, virtual: true)
    # field(:supplied_usertags, {:array, :string}, virtual: true)

    # TODO consider making message_type an enum
    field(:message_type, :string)

    belongs_to(:forwarded_message, __MODULE__)
    belongs_to(:replied_to, __MODULE__, foreign_key: :parent_id)
    belongs_to(:user, User)
    belongs_to(:room, Chat.Room)
    belongs_to(:private_post, Post)

    many_to_many(
      :hashtags_interest,
      Interest,
      join_through: __MODULE__.Interest,
      join_keys: [message_id: :id, interest_id: :id]
    )

    many_to_many(
      :usertags,
      User,
      join_through: __MODULE__.Usertag,
      join_keys: [message_id: :id, userprofile_id: :id]
    )

    many_to_many(
      :users_seen_message,
      User,
      join_through: __MODULE__.Seen,
      join_keys: [message_id: :id, userprofile_id: :id]
    )

    many_to_many :media_files, Upload,
      join_through: "message_uploads",
      join_keys: [message_id: :id, upload_key: :media_key],
      on_replace: :delete

    timestamps(updated_at: false)
  end

  def available(params) do
    from(m in not_blocked(params),
      inner_join: u in assoc(m, :user),
      where: u.banned? == false and u.deleted? == false
    )
  end

  @user_id_fk "chat_message_user_id_a47c01bb_fk_accounts_userprofile_id"
  @room_id_fk "chat_message_room_id_5e7d8d78_fk_chat_room_id"

  # TODO remove maybe_put_empty_string_for_empty_message
  # once the non null chat_message.message constraint is removed
  # for chat_message.message_type == "IMG"
  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(message, attrs) do
    message
    # TODO remove private_post_id once the requirements are clear
    |> cast(attrs, [:message, :message_type, :location, :private_post_id])
    |> put_assoc(:media_files, media_files_from_keys(attrs["media_file_keys"] || []))
    |> validate_required([:message_type])
    |> validate_inclusion(:message_type, ["IMG", "TXT", "VID", "PST", "AUD"])
    |> validate_length(:message, max: 3000)
    |> maybe_require_message()
    |> maybe_require_post()
    |> maybe_put_empty_string_for_empty_message()
    |> extract_supplied_hashtags(attrs)
    |> foreign_key_constraint(:user_id, name: @user_id_fk)
    |> foreign_key_constraint(:room_id, name: @room_id_fk)
  end

  @spec maybe_require_message(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_require_message(%{valid?: true, changes: %{message_type: "TXT"}} = changeset) do
    validate_required(changeset, [:message])
  end

  defp maybe_require_message(changeset), do: changeset

  @spec maybe_require_post(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_require_post(%{valid?: true, changes: %{message_type: "PST"}} = changeset) do
    validate_required(changeset, [:private_post_id])
  end

  defp maybe_require_post(changeset), do: changeset

  @spec maybe_put_empty_string_for_empty_message(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp maybe_put_empty_string_for_empty_message(%{valid?: true, changes: changes} = changeset) do
    case Map.get(changes, :message) do
      nil -> put_change(changeset, :message, "")
      _other -> changeset
    end
  end

  defp maybe_put_empty_string_for_empty_message(changeset), do: changeset

  @spec extract_supplied_hashtags(Ecto.Changeset.t(), BillBored.attrs()) :: Ecto.Changeset.t()
  defp extract_supplied_hashtags(changeset, %{"hashtags" => hashtags}) do
    put_change(changeset, :supplied_hashtags, Enum.filter(hashtags, &is_binary/1))
  end

  defp extract_supplied_hashtags(changeset, %{hashtags: hashtags}) do
    put_change(changeset, :supplied_hashtags, Enum.filter(hashtags, &is_binary/1))
  end

  defp extract_supplied_hashtags(changeset, _attrs) do
    put_change(changeset, :supplied_hashtags, [])
  end
end
