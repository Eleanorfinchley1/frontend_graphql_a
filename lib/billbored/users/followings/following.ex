defmodule BillBored.User.Followings.Following do
  @moduledoc "scheme for accounts_userprofile_follows table"

  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.User

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "accounts_userprofile_follows" do
    belongs_to(:from, User, foreign_key: :from_userprofile_id)
    belongs_to(:to, User, foreign_key: :to_userprofile_id)
    timestamps(updated_at: false)
  end

  @doc false
  def changeset(following, attrs) do
    following
    |> cast(attrs, [:from_userprofile_id, :to_userprofile_id])
    |> validate_required([:from_userprofile_id, :to_userprofile_id])
  end
end
