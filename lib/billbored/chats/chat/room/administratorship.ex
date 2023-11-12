defmodule BillBored.Chat.Room.Administratorship do
  @moduledoc "schema for chat_room_administrators table"

  use BillBored, :schema
  alias BillBored.{User, Chat}

  @type t :: %__MODULE__{}

  schema "chat_room_administrators" do
    belongs_to(:user, User, foreign_key: :userprofile_id)
    belongs_to(:room, Chat.Room)
  end
end
