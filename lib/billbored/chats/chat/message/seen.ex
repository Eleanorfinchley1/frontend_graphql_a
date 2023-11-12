defmodule BillBored.Chat.Message.Seen do
  @moduledoc "schema for chat_message_users_seen_message table"

  use BillBored, :schema
  alias BillBored.{User, Chat}

  @type t :: %__MODULE__{}

  schema "chat_message_users_seen_message" do
    belongs_to(:message, Chat.Message)
    belongs_to(:user, User, foreign_key: :userprofile_id)
  end
end
