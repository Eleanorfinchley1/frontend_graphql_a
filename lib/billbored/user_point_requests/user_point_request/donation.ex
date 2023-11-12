defmodule BillBored.UserPointRequest.Donation do
  @moduledoc "schema for user_point_donations table"
  require Logger

  use BillBored, :schema

  alias BillBored.User
  alias BillBored.UserPointRequest

  @type t :: %__MODULE__{}

  schema "user_point_donations" do
    field(:stream_points, :integer)

    belongs_to(:sender, User)
    belongs_to(:receiver, User)
    belongs_to(:request, UserPointRequest, foreign_key: :request_id)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  @castable [:stream_points, :request_id, :sender_id, :receiver_id]
  @required [:sender_id, :receiver_id, :request_id, :stream_points]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(audit, attrs) do
    audit
    |> cast(attrs, @castable)
    |> validate_required(@required)
    |> validate_number(:stream_points, greater_than: 0)
  end
end
