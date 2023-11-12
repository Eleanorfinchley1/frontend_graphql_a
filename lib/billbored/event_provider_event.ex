defmodule BillBored.EventProviderEvent do
  @moduledoc "schema for event_provider_events table"

  use BillBored, :schema
  alias BillBored.EventSynchronization

  @type t :: %__MODULE__{}

  @primary_key false
  schema "event_provider_events" do
    field(:event_provider, :string, primary_key: true)
    field(:provider_id, :string, primary_key: true)
    field(:data, :map)

    belongs_to(:event_synchronization, EventSynchronization)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  @valid_providers ~w(eventful meetup allevents)s

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_provider, :provider_id, :data])
    |> cast_assoc(:event_synchronization)
    |> validate_inclusion(:event_provider, @valid_providers)
  end
end
