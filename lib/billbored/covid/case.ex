defmodule BillBored.Covid.Case do
  use Ecto.Schema
  import Ecto.Changeset

  schema "covid_cases" do
    field :datetime, :utc_datetime_usec
    field :timeslot, :integer
    field :source_url, :string
    field :cases, :integer
    field :deaths, :integer
    field :recoveries, :integer
    field :active_cases, :integer

    belongs_to :location, BillBored.Covid.Location
  end

  @doc false
  def changeset(covid_case, attrs \\ %{}) do
    covid_case
    |> cast(attrs, [:datetime, :timeslot, :cases, :deaths, :recoveries, :active_cases, :location_id])
    |> cast_assoc(:location)
    |> validate_required([:datetime, :timeslot])
  end
end
