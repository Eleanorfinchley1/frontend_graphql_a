defmodule BillBored.EventSynchronization do
  @moduledoc "schema for event_synchronizations table"

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "event_synchronizations" do
    field(:event_provider, :string)
    field(:started_at, :utc_datetime_usec)
    field(:location, BillBored.Geo.Point)
    field(:radius, :float)
    field(:status, :string)

    has_many(:provider_events, BillBored.EventProviderEvent)
  end

  @valid_providers ~w(eventful meetup allevents)s
  @valid_statuses ~w(pending failed completed)s

  @doc false
  def changeset(report, attrs) do
    report
    |> cast(attrs, [:event_provider, :started_at, :location, :radius, :status])
    |> validate_inclusion(:event_provider, @valid_providers)
    |> validate_inclusion(:status, @valid_statuses)
  end
end
