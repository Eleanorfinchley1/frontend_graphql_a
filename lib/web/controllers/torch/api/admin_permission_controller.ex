defmodule Web.Torch.API.AdminPermissionController do
  use Web, :controller
  alias BillBored.AdminPermissions

  def list(%Plug.Conn{} = conn, _opts) do
    render(conn, "list.json", permissions: AdminPermissions.list)
  end

  def tree(%Plug.Conn{} = conn, _opts) do
    render(conn, "tree.json", permission: AdminPermissions.tree)
  end
end
