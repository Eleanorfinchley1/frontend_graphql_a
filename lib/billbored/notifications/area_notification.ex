defmodule BillBored.Notifications.AreaNotification do
  @moduledoc false

  use BillBored, :schema
  alias BillBored.Notifications.AreaNotifications.TimetableRun

  @required_fields [:owner_id, :message, :location, :radius]

  schema "area_notifications" do
    field :title, :string
    field :message, :string
    field :location, BillBored.Geo.Point
    field :radius, :float
    field :expires_at, :utc_datetime_usec
    field :receivers_count, :integer
    field :categories, {:array, :string}
    field :sex, :string
    field :min_age, :integer
    field :max_age, :integer
    field :timezone, :string

    belongs_to :owner, BillBored.User
    belongs_to :business, BillBored.User

    belongs_to :logo, BillBored.Upload,
      type: :string,
      foreign_key: :logo_media_key,
      references: :media_key

    belongs_to :image, BillBored.Upload,
      type: :string,
      foreign_key: :image_media_key,
      references: :media_key

    belongs_to :linked_post, BillBored.Post,
      foreign_key: :linked_post_id

    has_many :timetable_runs, TimetableRun
    has_many :timetable_entries, through: [:timetable_runs, :timetable_entry]

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def changeset(area_notification, attrs \\ %{}) do
    area_notification
    |> cast(
      attrs,
      @required_fields ++
        [
          :business_id, :title, :expires_at, :receivers_count, :logo_media_key, :image_media_key,
          :linked_post_id, :categories, :sex, :min_age, :max_age, :timezone
        ]
    )
    |> cast_assoc(:logo)
    |> cast_assoc(:image)
    |> cast_assoc(:linked_post)
    |> validate_required(@required_fields)
    |> validate_number(:min_age, greater_than_or_equal_to: 0, less_than_or_equal_to: 999)
    |> validate_number(:max_age, greater_than_or_equal_to: 0, less_than_or_equal_to: 999)
    |> validate_length(:sex, min: 1, max: 2)
    |> foreign_key_constraint(:image_media_key, name: :area_notifications_image_media_key_fkey)
    |> foreign_key_constraint(:logo_media_key, name: :area_notifications_logo_media_key_fkey)
    |> foreign_key_constraint(:linked_post, name: :area_notifications_linked_post_id_fkey)
  end
end
