defmodule BillBored.Chat.Room.DropchatStream.Reaction do
  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.User

  @type t :: %__MODULE__{}
  @valid_types ~w(like dislike clapping)

  schema "dropchat_streams_reactions" do
    field(:type, :string)

    belongs_to(:stream, DropchatStream)
    belongs_to(:user, User)

    timestamps(updated_at: false)
  end

  def valid_types(), do: @valid_types

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:type, :stream_id, :user_id])
    |> validate_inclusion(:type, @valid_types)
  end
end
