defmodule BillBored.Chat.Room.ElevatedPrivilege do
  @moduledoc "for dropchats"

  use Ecto.Schema
  alias BillBored.{Chat, User}

  @type t :: %__MODULE__{}

  schema "dropchat_elevated_privileges" do
    belongs_to(:user, User)
    belongs_to(:dropchat, Chat.Room)

    timestamps(updated_at: false, type: :naive_datetime_usec)
  end
end
