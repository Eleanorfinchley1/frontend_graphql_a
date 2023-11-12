defmodule BillBored.BusinessesCategories do
  @moduledoc "schema that represent relationship beteween categories and business account"

  use BillBored, :schema
  alias BillBored.{BusinessCategory, User}

  @type t :: %__MODULE__{}

  schema "businesses_categories" do
    belongs_to(:business_category, BusinessCategory)
    belongs_to(:user, User)
  end
end
