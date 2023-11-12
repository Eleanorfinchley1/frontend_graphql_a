defmodule BillBored.Place.Type do
  use Ecto.Schema

  schema "places_types" do
    field :name, :string
  end
end
