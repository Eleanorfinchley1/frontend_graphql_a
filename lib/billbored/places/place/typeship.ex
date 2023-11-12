defmodule BillBored.Place.Typeship do
  use BillBored, :schema
  alias BillBored.Place

  schema "places_typeship" do
    belongs_to :place, Place
    belongs_to :type, Place.Type
  end
end
