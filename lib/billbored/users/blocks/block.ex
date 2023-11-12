defmodule BillBored.User.Block do
  @moduledoc "schema for accounts_userprofile_blocked table"

  use BillBored, :schema
  alias BillBored.User

  @type t :: %__MODULE__{}

  schema "accounts_userprofile_blocked" do
    belongs_to(:blocker, User, foreign_key: :to_userprofile_id)
    belongs_to(:blocked, User, foreign_key: :from_userprofile_id)
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:to_userprofile_id, :from_userprofile_id])
    |> put_assoc(:blocker, attrs[:blocker])
    |> put_assoc(:blocked, attrs[:blocked])
  end
end
