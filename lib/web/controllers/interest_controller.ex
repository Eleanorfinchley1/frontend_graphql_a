defmodule Web.InterestController do
  use Web, :controller
  alias BillBored.Interests

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def index(conn, params, _user_id) do
    render(conn, "index.json", data: Interests.index(params))
  end

  def show(conn, %{"id" => id}, _opts) do
    interest = Interests.get!(id)
    render(conn, "show.json", interest: interest)
  end

  def categories(conn, _params, _opts) do
    categories = BillBored.InterestCategories.list_all()
    render(conn, "categories.json", categories: categories)
  end
end
