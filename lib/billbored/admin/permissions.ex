defmodule BillBored.AdminPermissions do
  def all do
    BillBored.AdminPermission.all_permissions
  end

  def list do
    BillBored.AdminPermission.all_permissions
    |> Map.to_list()
    |> Enum.sort(fn {key1, body1}, {key2, body2} ->
      Map.has_key?(body2, :included) and (not Map.has_key?(body1, :included) or not Enum.member?(body1.included, key2)) and key1 < key2
    end)
    |> Enum.map(fn {key, body} -> Map.put(body, :key, key) end)
  end

  def tree do
    list()
    |> Enum.reduce(%{}, fn permission, tree ->
      if permission.key == "*:*" do
        Map.put(permission, :children, [])
      else
        if Enum.member?(permission.included, "*:*") do
          children = tree.children ++ [permission]
          Map.put(tree, :children, children)
        else
          child = List.last(tree.children)
          children = List.delete(tree.children, child)
          child_children = if Map.has_key?(child, :children) do
            child.children ++ [permission]
          else
            [permission]
          end
          child = Map.put(child, :children, child_children)
          Map.put(tree, :children, children ++ [child])
        end
      end
    end)
  end

  def inclusions("*:*"), do: ["*:*"]

  def inclusions(key) do
    perms = BillBored.AdminPermission.all_permissions
    if Map.has_key?(perms, key) do
      perms = perms[key].included
      |> Enum.reduce([], fn item, all ->
        if Enum.member?(all, item) do
          all
        else
          all ++ inclusions(item)
        end
      end)
      |> Enum.uniq()
      perms ++ [key]
    else
      [key]
    end
  end
end
