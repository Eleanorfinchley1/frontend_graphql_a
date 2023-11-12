defmodule Web.Torch.API.UserController do
  use Web, :controller
  alias BillBored.Users

  def list_nearby(conn, %{"location" => [lat, long]}) do
    rendered_json = Web.UserView.render("list.json", users: Users.list_users_located_around_location(%BillBored.Geo.Point{lat: lat, long: long}))
    json(conn, rendered_json)
  end

  def list(conn, _opts) do
    rendered_json = Web.UserView.render("list.json", users: Users.list())
    json(conn, rendered_json)
  end
end
