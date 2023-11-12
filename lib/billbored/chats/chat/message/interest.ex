defmodule BillBored.Chat.Message.Interest do
  @moduledoc "schema for chat_message_hashtags table"

  use BillBored, :schema
  alias BillBored.{Interest, Chat}

  @type t :: %__MODULE__{}

  schema "chat_message_hashtags" do
    belongs_to(:message, Chat.Message)
    belongs_to(:interest, Interest)
  end
end
