defmodule BillBored.Chat.Message.Usertag do
  @moduledoc "schema for chat_message_usertags table"

  use Ecto.Schema
  alias BillBored.{User, Chat}

  @type t :: %__MODULE__{}

  schema "chat_message_usertags" do
    belongs_to(:message, Chat.Message)
    belongs_to(:user, User, foreign_key: :userprofile_id)
  end
end
