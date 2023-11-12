defmodule BillBored.LocationReward do
  @moduledoc "schema for location_rewards table"

  use BillBored, :schema

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
  only: [
    :location,
    :radius,
    :stream_points,
    :started_at,
    :ended_at,
    :inserted_at,
    :updated_at
  ]}

  schema "location_rewards" do
    field(:location, BillBored.Geo.Point)
    field(:radius, :float)
    field(:stream_points, :integer)
    field(:started_at, :utc_datetime_usec)
    field(:ended_at, :utc_datetime_usec)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  @required [:location, :radius, :stream_points, :started_at, :ended_at]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(point, attrs) do
    point
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required(@required)
  end
end
