defmodule BillBored.Chat.Room.DropchatStream.Speaker do
  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.User

  @type t :: %__MODULE__{}

  schema "dropchat_streams_speakers" do
    belongs_to(:stream, DropchatStream)
    belongs_to(:user, User)
    field :is_ghost, :boolean, default: false

    timestamps(updated_at: false)
  end

  def changeset(speaker, attrs) do
    speaker
    |> cast(attrs, [:stream_id, :user_id, :is_ghost])
  end
end
