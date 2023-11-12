defmodule BillBored.Chat.Room.ElevatedPrivilege.Request do
  @moduledoc "schema for chat_room_pending"

  use BillBored, :schema
  alias BillBored.{Chat, User}

  @type t :: %__MODULE__{}

  schema "chat_room_pending" do
    belongs_to(:user, User, foreign_key: :userprofile_id)
    belongs_to(:room, Chat.Room)
  end
end
