defmodule BillBored.Chat.Room.DropchatStream.SpeakerReaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.User

  @type t :: %__MODULE__{}

  @valid_types ~w(clapping)

  schema "dropchat_stream_speakers_reactions" do
    field(:type, :string)

    belongs_to(:stream, DropchatStream)
    belongs_to(:speaker, User)
    belongs_to(:user, User)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(reaction, attrs) do
    reaction
    |> cast(attrs, [:stream_id, :speaker_id, :user_id, :type])
    |> validate_inclusion(:type, @valid_types)
  end
end
