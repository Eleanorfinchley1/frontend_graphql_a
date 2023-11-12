defmodule Web.BusinessAccounts.StatsView do
  use Web, :view

  def render("post_views.json", %{views: views}) do
    %{
      views: Enum.map(views, fn %{count: count, location: _location} = view ->
        %{
          count: count,
          location: Web.LocationView.render("show.json", view)
        }
      end)
    }
  end
end
