defmodule BillBored.Covid.Location do
  use Ecto.Schema
  import Ecto.Changeset

  schema "covid_locations" do
    field :country_code, :string
    field :scope, :string
    field :country, :string
    field :state, :string
    field :county, :string
    field :city, :string
    field :region, :string
    field :source_population, :integer
    field :population, :integer
    field :source_location, BillBored.Geo.Point
    field :location, BillBored.Geo.Point
  end

  @doc false
  def changeset(covid_location, attrs) do
    covid_location
    |> cast(attrs, [:country_code, :country, :scope, :region, :population, :location])
    |> validate_length(:country_code, max: 3)
    |> validate_length(:country, max: 120)
    |> validate_length(:scope, max: 40)
    |> validate_length(:region, max: 255)
    |> validate_required([:country_code, :scope])
  end
end
