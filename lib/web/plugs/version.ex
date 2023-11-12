defmodule Web.Plugs.Version do
  @moduledoc "Adds a version header with commit sha of the build to the response"

  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    <<short::12-bytes, _rest::bytes>> = BillBored.Version.commit_sha()
    put_resp_header(conn, "x-version", short)
  end
end
