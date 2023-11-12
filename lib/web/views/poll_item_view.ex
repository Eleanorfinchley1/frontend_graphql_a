defmodule Web.PollItemView do
  use Web, :view

  def render("show.json", %{item: item}) do
    item
    |> Map.take([:id, :title, :user_voted?, :votes_count])
    # TODO rename to media_files
    |> Map.put(:media_file_keys, render_many(item.media_files, Web.MediaView, "file.json"))
  end
end
