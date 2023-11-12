defmodule BillBored.Torch.LocationRewardDecorator do
  @moduledoc false

  import Ecto.Changeset
  use Ecto.Schema

  @required_fields [
    :latitude,
    :longitude,
    :radius,
    :stream_points,
    :started_at,
    :ended_at
  ]
  @max_radius_m 100.0

  @primary_key false
  embedded_schema do
    field :latitude, :float
    field :longitude, :float
    field :radius, :float
    field :stream_points, :integer
    field :started_at, :utc_datetime_usec
    field :ended_at, :utc_datetime_usec
  end

  def changeset(decorator, attrs \\ %{}) do
    decorator
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:latitude, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:longitude, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:radius, greater_than: 0, less_than_or_equal_to: @max_radius_m)
  end

end
