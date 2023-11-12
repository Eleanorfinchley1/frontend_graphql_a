defmodule BillBored.InterestCategory do
  import Ecto.Changeset
  use BillBored, :schema

  schema "interest_categories" do
    field(:name, :string)
    field(:icon, :string)
    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)

    many_to_many(:interests, BillBored.Interest, join_through: "interest_categories_interests", on_replace: :delete)
  end

  def changeset(interest_category, attrs \\ %{}) do
    interest_category
    |> cast(attrs, [:name, :icon])
    |> put_assoc(:interests, attrs[:interests])
    |> validate_required([:name])
  end
end
