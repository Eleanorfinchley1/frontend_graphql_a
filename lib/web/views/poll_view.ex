defmodule Web.PollView do
  use Web, :view

  def render("show.json", %{poll: poll}) do
    poll
    |> Map.take([:id, :inserted_at, :updated_at, :post_id, :question])
    |> Map.put(:items, render_many(poll.items, Web.PollItemView, "show.json", as: :item))
  end
end
