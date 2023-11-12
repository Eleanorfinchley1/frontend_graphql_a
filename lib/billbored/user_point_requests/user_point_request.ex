defmodule BillBored.UserPointRequest do
  @moduledoc "schema for user_point_requests table"

  use BillBored, :schema
  use BillBored.User.Blockable, foreign_key: :user_id

  alias BillBored.User

  @type t :: %__MODULE__{}

  schema "user_point_requests" do
    belongs_to(:user, User)
    has_many(:donations, __MODULE__.Donation, foreign_key: :request_id)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  @required [:user_id]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(point_request, attrs) do
    point_request
    |> cast(attrs, [])
    |> validate_required(@required)
  end
end
