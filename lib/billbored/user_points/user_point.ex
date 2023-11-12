defmodule BillBored.UserPoint do
  @moduledoc "schema for user_points table"

  use BillBored, :schema
  use BillBored.User.Blockable, foreign_key: :user_id

  alias BillBored.User

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
  only: [
    :stream_points,
    :general_points
  ]}

  @primary_key false
  schema "user_points" do
    field(:stream_points, :integer)
    field(:general_points, :integer)

    belongs_to(:user, User, foreign_key: :user_id, primary_key: true)
  end

  @castable [:stream_points, :general_points, :user_id]
  @required [:user_id, :stream_points, :general_points]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(point, attrs) do
    point
    |> cast(attrs, @castable)
    |> validate_required(@required)
    |> check_constraint(:stream_points, name: :stream_points_must_be_greater_than_0, message: "stream_points can't be less than 0")
    |> check_constraint(:general_points, name: :general_points_must_be_greater_than_0, message: "general_points can't be less than 0")
  end
end
