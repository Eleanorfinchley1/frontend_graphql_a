defmodule Web.UserPointView do
  use Web, :view

  alias BillBored.UserPoints

  def render("show.json", %{user: user}) do
    if is_nil(user.points) or not Ecto.assoc_loaded?(user.points) do
      points = UserPoints.get(user.id)
      render("show.json", %{user_points: points})
    else
      render("show.json", %{user_points: user.points})
    end
  end

  def render("show.json", %{user_id: user_id}) do
    points = UserPoints.get(user_id)
    render("show.json", %{user_points: points})
  end

  def render("show.json", %{user_points: points}) do
    result = %{stream_points: 0.0, general_points: 0.0}
    if is_nil(points) do
      result
    else
      Map.merge(result, %{stream_points: points.stream_points / 10, general_points: points.general_points / 10})
    end
  end
end
