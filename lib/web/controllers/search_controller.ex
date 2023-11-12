defmodule Web.SearchController do
  use Web, :controller
  alias BillBored.Search

  def search_all(conn, %{"q" => query}) do
    render(conn, "search_result.json", Search.search_all(query))
  end

  # TODO remove
  def example(conn, _params) do
    render(conn, "example.html", token: last_token())
  end

  # TODO remove
  defp last_token do
    import Ecto.Query

    token =
      BillBored.User.AuthToken
      |> last()
      |> Repo.one()

    token.key
  end
end
