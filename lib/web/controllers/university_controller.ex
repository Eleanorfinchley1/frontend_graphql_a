defmodule Web.UniversityController do
  use Web, :controller

  action_fallback Web.FallbackController

  alias BillBored.Universities
  alias BillBored.University

  def list(conn, %{"allowed" => allowed}) when allowed in ["true", "false"] do
    universities = Universities.get_by_allowance(allowed)
    render(conn, "index.json", universities: universities)
  end

  def list(conn, _params) do
    universities = Universities.list()
    render(conn, "index.json", universities: universities)
  end

  def get(conn, %{"id" => id}) do
    university = Universities.get_by_id(id)
    render(conn, "show.json", university: university)
  end

  def create(conn, params) do
    with {:ok, university} <- Universities.create(params) do
        render(conn, "show.json", university: university)
    end
  end

  def delete(conn, %{"id" => id}) do
    with %University{} <- Universities.delete(id) do
      send_resp(conn, 204, [])
    end
  end
end
