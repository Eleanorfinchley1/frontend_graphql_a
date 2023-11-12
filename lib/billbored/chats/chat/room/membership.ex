defmodule BillBored.Chat.Room.Membership do
  @moduledoc "schema for chat_room_users table"

  use BillBored, :schema
  alias BillBored.{User, Chat}

  @type t :: %__MODULE__{}

  @valid_roles ~w(guest member moderator administrator)

  schema "chat_room_users" do
    belongs_to(:user, User, foreign_key: :userprofile_id)
    belongs_to(:room, Chat.Room)
    field :muted?, :boolean
    field :role, :string
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:userprofile_id, :room_id, :muted?, :role])
    |> validate_required([:userprofile_id, :room_id])
    |> validate_inclusion(:role, @valid_roles)
  end
end
