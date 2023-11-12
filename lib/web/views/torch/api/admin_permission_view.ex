defmodule Web.Torch.API.AdminPermissionView do
  use Web, :view

  def render("list.json", %{permissions: permissions}) do
    permissions
    |> Enum.map(fn child -> render("permission.json", %{permission: child}) end)
  end

  def render("tree.json", %{permission: root_permission}) do
    render("permission.json", %{permission: root_permission})
  end

  def render("permission.json", %{permission: %{key: key, label: label, children: children}}) do
    %{
      key: key,
      label: label,
      children: Enum.map(children, fn child -> render("tree.json", %{permission: child}) end)
    }
  end

  def render("permission.json", %{permission: %{key: key, label: label}}) do
    %{
      key: key,
      label: label
    }
  end
end
