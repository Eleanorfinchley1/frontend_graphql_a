defmodule BillBored.User.CloseFriendship do
  @moduledoc "schame for accounts_userprofile_close_friends table"

  use BillBored, :schema
  import Ecto.Changeset
  alias BillBored.User

  @type t :: %__MODULE__{}

  schema "accounts_userprofile_close_friends" do
    belongs_to(:from, User, foreign_key: :from_userprofile_id)
    belongs_to(:to, User, foreign_key: :to_userprofile_id)
  end

  def changeset(close_friendship, attrs) do
    close_friendship
    |> cast(attrs, [:from_userprofile_id, :to_userprofile_id])
    |> validate_required([:from_userprofile_id, :to_userprofile_id])
    |> unique_constraint(
      :user_from_user_to,
      name: :accounts_userprofile_clo_from_userprofile_id_to_u_a9366b0c_uniq
    )
  end
end
