defmodule BillBored.Chat.Room.DropchatBan do
  @moduledoc "for dropchats"

  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.{Chat, User}

  @type t :: %__MODULE__{}

  schema "dropchat_bans" do
    belongs_to(:dropchat, Chat.Room)
    belongs_to(:admin, User)
    belongs_to(:banned_user, User)

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(ban, attrs) do
    ban
    |> cast(attrs, [:dropchat_id, :admin_id, :banned_user_id])
    |> put_assoc(:dropchat, attrs[:dropchat])
    |> put_assoc(:admin, attrs[:admin])
    |> put_assoc(:banned_user, attrs[:banned_user])
    |> validate_required([:dropchat, :admin, :banned_user])
  end
end
