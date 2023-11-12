defmodule Web.Torch.UserView do
  use Web, :view

  import Torch.TableView
  import Torch.FilterView

  def render("index_with_activities.json", %{entries: entries} = scrivener) do
    rendered_users =
      Enum.map(entries, fn user ->
        %{
          id: user.id,
          username: user.username,
          general_points: (user.points || %{general_points: 0}).general_points,
          streams_count: user.streams_count,
          claps_count: user.claps_count,
          university_name: (user.university || %{name: nil}).name,
          last_online_at: user.last_online_at,
          date_joined: user.date_joined
        }
      end)

    scrivener
    |> Map.take([:page_number, :page_size, :total_pages, :total_entries])
    |> Map.put(:entries, rendered_users)
  end
end
