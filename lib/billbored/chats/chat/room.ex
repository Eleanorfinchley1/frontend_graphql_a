defmodule BillBored.Chat.Room do
  use BillBored, :schema
  alias BillBored.{Interest, User, Place}
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @default_key_length 20
  @color "#FF006D"

  # km
  @max_radius 60
  @min_radius 0.1

  schema "chat_room" do
    field(:key, :string)

    # TODO correct assumption?
    field(:private, :boolean, default: true)
    field(:location, BillBored.Geo.Point)
    field(:last_interaction, :utc_datetime_usec)
    field(:title, :string)
    field(:chat_type, :string)
    field(:color, :string, default: @color)
    field(:ghost_allowed, :boolean)

    field(:last_message, :map, virtual: true)
    field(:messages_count, :integer, default: 0, virtual: true)

    field(:users, {:array, :map}, virtual: true)
    field(:university, :map, virtual: true)

    # in km
    field(:reach_area_radius, :decimal)
    field(:is_access_required, :boolean, virtual: true)
    field(:reactions_count, :map, virtual: true)
    field(:row_num, :integer, virtual: true)
    field(:is_recent, :boolean, virtual: true)

    belongs_to(:interest, Interest)
    belongs_to(:place, Place)

    many_to_many(
      :pending,
      User,
      join_through: __MODULE__.ElevatedPrivilege.Request,
      join_keys: [room_id: :id, userprofile_id: :id]
    )

    many_to_many(
      :interests,
      Interest,
      join_through: __MODULE__.Interestship,
      join_keys: [room_id: :id, interest_id: :id]
    )

    many_to_many(
      :participants,
      User,
      join_through: __MODULE__.Membership,
      join_keys: [room_id: :id, userprofile_id: :id,]
    )

    many_to_many(
      :members,
      User,
      join_through: __MODULE__.Membership,
      join_keys: [room_id: :id, userprofile_id: :id,],
      join_where: [role: "member"]
    )

    many_to_many(
      :moderators,
      User,
      join_through: __MODULE__.Membership,
      join_keys: [room_id: :id, userprofile_id: :id],
      join_where: [role: "moderator"]
    )

    many_to_many(
      :administrators,
      User,
      join_through: __MODULE__.Administratorship,
      join_keys: [room_id: :id, userprofile_id: :id]
    )

    has_many :streams, __MODULE__.DropchatStream, foreign_key: :dropchat_id

    has_one :active_stream,
      __MODULE__.DropchatStream,
      foreign_key: :dropchat_id,
      where: [status: "active"]

    timestamps(updated_at: false)
  end

  @fields [
    :key,
    #    :private?,
    :private,
    :location,
    :last_interaction,
    # interacted_at,
    :title,
    :chat_type,
    :color,
    :ghost_allowed,
    :reach_area_radius
  ]

  defp wrap_location(%{"location" => [lat, lng]} = attrs) do
    %{
      attrs
      | "location" => %{
          "coordinates" => [lat, lng],
          "crs" => %{
            "properties" => %{"name" => "EPSG:4326"},
            "type" => "name"
          },
          "type" => "Point"
        }
    }
  end

  defp wrap_location(attrs), do: attrs

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(room, attrs) do
    attrs = wrap_location(attrs)

    room
    |> cast(attrs, @fields)
    |> maybe_generate_key()
    |> validate_required([:key, :chat_type, :title, :last_interaction])
    |> validate_type(:chat_type)
    |> validate_length(:key, greater_than: 5)
    |> validate_length(:color, is: 7)
    |> validate_format(:color, ~r/^\#[0-9A-F]{6}$/)
    |> validate_number(:reach_area_radius, greater_than: @min_radius, less_than: @max_radius)
  end

  defp maybe_generate_key(changeset) do
    case get_field(changeset, :key) do
      nil ->
        generated_key = :crypto.strong_rand_bytes(@default_key_length) |> Base.url_encode64() |> binary_part(0, @default_key_length)
        put_change(changeset, :key, generated_key)

      _ ->
        changeset
    end
  end

  defp validate_type(changeset, field) do
    changeset =
      changeset
      |> validate_inclusion(field, ["dropchat", "one-to-one", "private-group-chat"])

    case get_field(changeset, field) do
      "dropchat" ->
        changeset
        |> validate_required([:reach_area_radius, :location])
        |> validate_inclusion(:private, [false])

      _other ->
        changeset
        |> validate_inclusion(:private, [true])
    end
  end
end
