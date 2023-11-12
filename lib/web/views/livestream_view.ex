defmodule Web.LivestreamView do
  use Web, :view
  alias BillBored.{Livestream, User}

  def render("comment.json", %{
        comment: %Livestream.Comment{id: id, body: body},
        author: %User{username: username}
      }) do
    %{
      "comment" => %{"id" => id, "body" => body},
      "author" => %{"username" => username}
    }
  end

  def render("livestream_created.json", %{
        livestream: %Livestream{
          id: id,
          title: title,
          location: location,
          active?: active?,
          recorded?: recorded?
        }
      }) do
    %{
      "id" => id,
      "title" => title,
      "coordinates" => Web.LocationView.render("coordinates.json", %{location: location}),
      "active?" => active?,
      "recorded?" => recorded?,
      "universal_link" => Web.Helpers.universal_link(id, %{schema: BillBored.Livestream})
    }
  end

  def render("livestream.json", %{
        livestream: %Livestream{} = livestream
      }) do
    user = Web.UserView.render("user.json", %{user: livestream.owner})

    render("livestream_created.json", %{livestream: livestream})
    |> Map.put("user", user)
  end

  def render("livestreams.json", %{livestreams: livestreams}) do
    Enum.map(livestreams, fn %Livestream{} = livestream ->
      render("livestream.json", %{livestream: livestream})
    end)
  end
end
