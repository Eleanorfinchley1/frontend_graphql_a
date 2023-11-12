defmodule Web.Plugs.TorchCheckPermissions do
  @moduledoc """
  """

  @behaviour Plug
  use Web, :plug
  import Phoenix.Controller, only: [action_name: 1]
  alias BillBored.AdminPermissions

  @impl true
  def init(opts), do: opts

  defp get_required_permission(conn, opts) do
    action = action_name(conn)
    opts
    |> Keyword.fetch!(:required_permission)
    |> Keyword.fetch(action)
  end

  @impl true
  def call(%Plug.Conn{assigns: %{admin_perms: allowed_permissions}} = conn, opts) when not is_nil(allowed_permissions) do
    case get_required_permission(conn, opts) do
      {:ok, required_permission} ->
        allowed = AdminPermissions.inclusions(required_permission)
          |> Enum.reduce(false, fn permission, allowed ->
            allowed || Enum.member?(allowed_permissions, permission)
          end)
        if allowed do
          conn
        else
          forbidden(conn, opts)
        end
      _ ->
        forbidden(conn, opts)
    end
  end

  def call(conn, opts) do
    case get_required_permission(conn, opts) do
      {:ok, _required_permission} ->
        forbidden(conn, opts)
      _ ->
        conn
    end
  end

  def forbidden(conn, _opts) do
    conn
      |> send_resp(:forbidden, "You don't have permission to access this.")
      |> halt()
  end
end
