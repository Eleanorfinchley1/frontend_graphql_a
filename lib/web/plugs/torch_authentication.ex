defmodule Web.Plugs.TorchAuthentication do
  @moduledoc """
  """

  @behaviour Plug
  use Web, :plug
  alias BillBored.Admin

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{assigns: %{admin: admin}} = conn, _opts) when not is_nil(admin) do
    permissions = Admin.Roles.get_permissions_by_admin_id(admin.id)
    permissions = permissions
      |> Enum.reduce([], fn item, perms ->
        perms ++ item
      end)
      |> Enum.uniq()
    assign(conn, :admin_perms, permissions)
  end

  def call(conn, _opts), do: unauthorized(conn)

  defp unauthorized(conn) do
    conn
    |> put_resp_header("www-authenticate", "Bearer")
    |> send_resp(:unauthorized, "")
    |> halt()
  end
end
