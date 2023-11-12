defmodule Web.PointRequestView do
  use Web, :view

  def render("show.json", %{request: request}) do
    %{
      id: request.id,
      user_id: request.user_id,
      inserted_at: request.inserted_at
    }
  end
end
