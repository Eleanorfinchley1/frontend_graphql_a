defmodule BillBored.Chat.Room.DropchatStream do
  @moduledoc "for dropchats"

  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.{Chat, User}

  @type t :: %__MODULE__{}

  @valid_statuses ~w(active finished)
  @default_key_length 8

  defmodule RecordingData do
    use Ecto.Schema

    @valid_statuses ~w(started in_progress finished failed expired)

    @primary_key false
    embedded_schema do
      field :status, :string
      field :uid, :string
      field :resource_id, :string
      field :sid, :string
      field :files, {:array, :map}
    end

    def valid_statuses(), do: @valid_statuses

    def changeset(recording_data, attrs) do
      recording_data
      |> cast(attrs, [:status, :uid, :resource_id, :sid, :files])
      |> validate_required([:status])
    end
  end

  schema "dropchat_streams" do
    field :key, :string
    field :title, :string
    field :status, :string
    field :reactions_count, :map
    field :flags, :map, default: %{}
    field :last_audience_count, :integer
    field :user_reactions, :map, virtual: true
    field :live_audience_count, :integer, virtual: true, default: 0
    field :peak_audience_count, :integer, virtual: true, default: 0
    field :finished_at, :utc_datetime_usec

    embeds_one :recording_data, RecordingData, on_replace: :update
    field :recording_updated_at, :utc_datetime_usec

    belongs_to(:dropchat, Chat.Room)
    belongs_to(:admin, User)

    has_many(
      :through_speakers,
      __MODULE__.Speaker,
      foreign_key: :stream_id, on_replace: :delete
    )

    has_many(
      :speakers,
      through: [:through_speakers, :user]
    )

    many_to_many(
      :reacted_users,
      User,
      join_through: __MODULE__.Reaction,
      join_keys: [stream_id: :id, user_id: :id]
    )

    timestamps(updated_at: false)
  end

  def create_changeset(dropchat_stream, attrs) do
    dropchat_stream
    |> cast(attrs, [:dropchat_id, :admin_id, :key, :title, :status, :flags, :finished_at])
    |> maybe_generate_key()
    |> validate_length(:key, greater_than: 5, less_than: 16)
    |> validate_inclusion(:status, @valid_statuses)
    |> put_assoc(:dropchat, attrs[:dropchat])
    |> put_assoc(:admin, attrs[:admin])
    |> validate_required([:dropchat, :admin, :key, :title, :status])
  end

  def update_changeset(dropchat_stream, attrs) do
    dropchat_stream
    |> cast(attrs, [:dropchat_id, :admin_id, :status, :flags, :recording_updated_at, :finished_at])
    |> cast_embed(:recording_data)
    |> validate_inclusion(:status, @valid_statuses)
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
end
