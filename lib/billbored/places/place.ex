defmodule BillBored.Place do
  use BillBored, :schema

  @sources ["google maps", "osm"]

  schema "places" do
    field(:name, :string)
    field(:place_id, :string)
    field(:location, BillBored.Geo.Point)
    field(:address, :string)
    field(:icon, :string)
    field(:vicinity, :string, default: "")
    field(:source, :string, default: "google maps")

    field(:distance, :integer, virtual: true)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)

    many_to_many(:types, __MODULE__.Type, join_through: __MODULE__.Typeship)
  end

  def changeset(place, attrs) do
    place
    |> cast(attrs, [:name, :place_id, :address, :icon, :vicinity, :location, :distance, :source])
    |> validate_inclusion(:source, @sources)
  end
end
