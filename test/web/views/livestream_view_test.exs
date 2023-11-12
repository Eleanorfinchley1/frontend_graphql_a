defmodule Web.LivestreamViewTest do
  use Web.ConnCase, async: true
  import Phoenix.View
  alias BillBored.{Livestream, User}

  test "livestream.json" do
    %User{} = _user = insert(:user)

    %Livestream{id: id, title: title} =
      livestream = insert(:livestream, location: %BillBored.Geo.Point{lat: 30.5, long: -30.5})

    assert render(Web.LivestreamView, "livestream_created.json", livestream: livestream) ==
             %{
               "id" => id,
               "title" => title,
               "coordinates" => %{
                 longitude: -30.5,
                 latitude: 30.5
               },
               "active?" => false,
               "recorded?" => false,
               "universal_link" => Web.Helpers.universal_link(id, %{schema: Livestream})
             }
  end

  test "comment.json" do
    %User{} = author = insert(:user)

    %Livestream.Comment{id: id, body: body} =
      comment = insert(:livestream_comment, author: author)

    assert render(Web.LivestreamView, "comment.json", comment: comment, author: author) == %{
             "author" => %{"username" => author.username},
             "comment" => %{"id" => id, "body" => body}
           }
  end
end
