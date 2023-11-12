defmodule BillBored.BusinessCategory do
  @moduledoc "schema that represent a business category"

  use BillBored, :schema

  @type t :: %__MODULE__{}

  schema "business_categories" do
    field(:category_name, :string)

    timestamps(inserted: :created, updated_at: :updated)
  end

  @required_fields ~w(category_name)a

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, @required_fields)
  end
end
