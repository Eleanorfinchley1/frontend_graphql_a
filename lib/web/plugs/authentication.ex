defmodule Web.Plugs.Authentication do
  @moduledoc """
  Checks for a user id in assigns
  """

  @behaviour Plug
  use Web, :plug

  def init(opts) do
    Keyword.fetch!(opts, :allowed_registration_statuses)
  end

  def call(%Plug.Conn{assigns: %{user_id: user_id, user_registration_status: reg_status}} = conn, allowed_statuses) when is_integer(user_id) do
    if reg_status in allowed_statuses do
      conn
    else
      unauthorized(conn)
    end
  end

  def call(conn, _opts), do: unauthorized(conn)

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", "Bearer")
    |> send_resp(:unauthorized, "")
    |> halt()
  end
end
