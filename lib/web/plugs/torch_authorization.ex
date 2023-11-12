defmodule Web.Plugs.TorchAuthorization do
  @moduledoc """
  Reads user id from bearer token.
  """

  @behaviour Plug
  use Web, :plug
  alias BillBored.Admins

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{req_headers: req_headers} = conn, _opts) do
    case :proplists.get_value("authorization", req_headers) do
      "Bearer " <> token ->
        case Admins.get_by_token(token) do
          {:ok, admin} ->
            assign(conn, :admin, admin)

          {:error, reason} ->
            conn
            |> send_resp(:unauthorized, Atom.to_string(reason))
            |> halt()

          _ ->
            conn
            |> send_resp(:unauthorized, "invalid token")
            |> halt()
        end

      _ ->
        conn
        |> put_resp_header("www-authenticate", "Bearer")
        |> send_resp(:unauthorized, "")
        |> halt()
    end
  end
end
