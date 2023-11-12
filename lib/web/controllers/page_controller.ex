defmodule Web.PageController do
  use Web, :controller

  def index(conn, _params) do
    send_resp(conn, 200, [])
  end
end
