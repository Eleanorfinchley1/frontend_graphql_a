defmodule Web.BusinessView do
  use Web, :view
  alias BillBored.BusinessCategory

  def render("business_category.json", %{
        business_category: %BusinessCategory{
          id: id,
          category_name: category_name
        }
      }) do
    %{
      "id" => id,
      "category" => category_name
    }
  end

  def render("categories.json", %{categories: categories}) do
    Enum.map(categories, fn %BusinessCategory{} = business_category ->
      render("business_category.json", %{business_category: business_category})
    end)
  end
end
