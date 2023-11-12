defmodule BillBored.Chat.Room.Interestship do
  @moduledoc "schema for chat_room_interests table"

  use BillBored, :schema
  alias BillBored.{Chat, Interest}

  @type t :: %__MODULE__{}

  schema "chat_room_interests" do
    belongs_to(:interest, Interest)
    belongs_to(:room, Chat.Room)
  end
end
