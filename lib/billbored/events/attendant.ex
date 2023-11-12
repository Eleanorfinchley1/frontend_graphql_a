defmodule BillBored.Event.Attendant do
  use BillBored, :schema

  alias BillBored.{Event, User}

  @type t :: %__MODULE__{}

  schema "events_attendees" do
    field :status, :string, default: "invited"

    belongs_to(:event, Event)
    belongs_to(:user, User)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def statuses() do
    %{
      future: ["invited", "refused", "accepted", "doubts"],
      past: ["presented", "missed"]
    }
  end

  def changeset(events_attendant, attrs) do
    events_attendant
    |> cast(attrs, [
      :status,
      :event_id,
      :user_id
    ])
    |> validate_inclusion(:status, statuses().future ++ statuses().past)
    |> foreign_key_constraint(:event_id)
    |> foreign_key_constraint(:user_id)
  end
end
