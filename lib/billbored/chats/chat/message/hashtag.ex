defmodule BillBored.Chat.Message.Hashtag do
  @moduledoc "schema for chat_message_custom_hashtags table"

  use Ecto.Schema
  alias BillBored.{Hashtag, Chat}

  @type t :: %__MODULE__{}

  schema "chat_message_custom_hashtags" do
    belongs_to(:message, Chat.Message)
    belongs_to(:hashtag, Hashtag)

    timestamps(updated_at: false, type: :naive_datetime_usec)
  end
end
