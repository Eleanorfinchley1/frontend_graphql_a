defmodule Web.InterestCategoryView do
  use Web, :view

  def render("show.json", %{interest_category: interest_category}) do
    Map.take(interest_category, [:name, :icon])
  end
end
