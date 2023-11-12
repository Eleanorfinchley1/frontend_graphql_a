defmodule BillBored.Event do
  use BillBored, :schema
  alias BillBored.{Post, Place, User, Event, Upload}

  import Ecto.Changeset
  import BillBored.Helpers, only: [media_files_from_keys: 1]

  @type t :: %__MODULE__{}

  schema "events" do
    field(:title, :string)
    field(:categories, {:array, :string}, default: [])

    many_to_many :media_files, Upload,
      join_through: "event_uploads",
      join_keys: [event_id: :id, upload_key: :media_key],
      on_replace: :delete

    field(:eventbrite_urls, {:array, :string})
    field(:eventful_urls, {:array, :string})
    field(:provider_urls, {:array, :string})

    field(:date, :utc_datetime_usec, source: :begin_date)
    field(:other_date, :utc_datetime_usec, source: :end_date)

    field(:price, :float)
    field(:currency, :string, default: "USD")
    field(:buy_ticket_link, :string)
    field(:child_friendly, :boolean, default: false)

    field(:user_status, :string, virtual: true)

    field(:invited_count, :integer, default: 0, virtual: true)
    field(:refused_count, :integer, default: 0, virtual: true)
    field(:accepted_count, :integer, default: 0, virtual: true)
    field(:doubts_count, :integer, default: 0, virtual: true)
    field(:missed_count, :integer, default: 0, virtual: true)
    field(:presented_count, :integer, default: 0, virtual: true)

    field(:location, BillBored.Geo.Point)

    field(:eventbrite_id, :integer)
    field(:eventful_id, :string)

    field(:event_provider, :string)
    field(:provider_id, :string)

    belongs_to(:post, Post)
    belongs_to(:place, Place)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)

    many_to_many(:attendees, User,
      join_through: Event.Attendant,
      join_keys: [event_id: :id, user_id: :id]
    )
  end

  @valid_event_providers ~w(eventful meetup allevents)s

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title,
      :categories,
      :post_id,
      :date,
      :other_date,
      :location,
      :price,
      :currency,
      :buy_ticket_link,
      :child_friendly,
      :place_id,
      :event_provider,
      :provider_id
    ])
    |> put_assoc(:media_files, media_files_from_keys(attrs["media_file_keys"] || []))
    |> validate_required([:date, :location])
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:place_id)
    |> validate_dates()
    |> validate_inclusion(:event_provider, @valid_event_providers)
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :date)

    changeset =
      unless DateTime.compare(start_date, DateTime.utc_now()) == :gt do
        add_error(changeset, :date, "must be a moment in the future")
      end || changeset

    if end_date = get_field(changeset, :other_date) do
      unless DateTime.compare(end_date, start_date) == :gt do
        add_error(changeset, :other_date, "must be later than the begining date")
      end
    end || changeset
  end
end
