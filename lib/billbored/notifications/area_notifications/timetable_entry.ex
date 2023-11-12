defmodule BillBored.Notifications.AreaNotifications.TimetableEntry do
  @moduledoc false

  use BillBored, :schema

  schema "area_notifications_timetable_entries" do
    field :time, :time
    field :categories, {:array, :string}
    field :any_category, :boolean, default: false
    field :template, :string

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def changeset(entry, attrs \\ %{}) do
    entry
    |> cast(attrs, [:time, :categories, :any_category, :template])
    |> maybe_clear_categories()
  end

  defp maybe_clear_categories(changeset) do
    case get_change(changeset, :any_category) do
      true ->
        put_change(changeset, :categories, [])

      _ ->
        changeset
    end
  end
end
