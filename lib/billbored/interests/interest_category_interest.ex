defmodule BillBored.InterestCategoryInterest do
  import Ecto.Changeset
  use BillBored, :schema

  schema "interest_categories_interests" do
    belongs_to(:interest, BillBored.Interest)
    belongs_to(:interest_category, BillBored.InterestCategory)
  end

  def changeset(schema, attrs \\ %{}) do
    schema
    |> cast(attrs, [:interest_id, :interest_category_id])
    |> cast_assoc(:interest)
    |> cast_assoc(:interest_category)
    |> validate_required([:interest, :interest_category])
  end
end
