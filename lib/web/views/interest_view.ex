defmodule Web.InterestView do
  use Web, :view

  @fields [:id, :hashtag, :icon, :disabled?, :inserted_at]

  def render("index.json", %{conn: conn, data: interests}) do
    Web.ViewHelpers.index(conn, interests, Web.InterestView)
  end

  def render("show.json", %{interest: interest}) do
    fields =
      if interest.popularity do
        @fields ++ [:popularity]
      else
        @fields
      end

    Map.take(interest, fields)
  end

  def render("categories.json", %{categories: categories}) do
    Phoenix.View.render_many(categories, Web.InterestCategoryView, "show.json")
  end

  def render("min.json", %{interest: interest}) do
    fields = @fields -- [:disabled?, :inserted_at, :id]
    Map.take(interest, fields)
  end

  def render("list.json", %{data: interests}) do
    interests
    |> Enum.map(fn interest -> render("min.json", %{interest: interest}) end)
  end
end
