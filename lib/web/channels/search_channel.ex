defmodule Web.SearchChannel do
  use Web, :channel
  alias BillBored.Search

  def join("search", _params, socket) do
    {:ok, socket}
  end

  def handle_in("search", %{"query" => query}, socket) do
    reply = Web.SearchView.render("search_result.json", Search.search_all(query))
    {:reply, {:ok, reply}, socket}
  end
end
