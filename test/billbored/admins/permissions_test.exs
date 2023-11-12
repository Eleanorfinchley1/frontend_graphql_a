defmodule BillBored.AdminPermissionsTest do
  use BillBored.DataCase, async: true
  alias BillBored.AdminPermissions

  test "validate permissions" do
    permissions = AdminPermissions.all

    permissions
    |> Map.keys()
    |> Enum.each(fn key ->
      permission = permissions[key]
      # permission must have label
      assert Map.has_key?(permission, :label)
      # permission label can't be empty
      assert permission[:label] != ""
      if key == "*:*" do
        # *:* permission can't have included
        assert not Map.has_key?(permission, :included)
      else
        # else must have included
        assert Map.has_key?(permission, :included)
        # included must be list
        assert is_list(permission[:included])
        # included list can't be empty
        assert length(permission[:included]) > 0
        Enum.each(permission[:included], fn included_in ->
          # inclusion must exist
          assert Map.has_key?(permissions, included_in)
        end)
      end
    end)
  end

  test "inclusions" do
    permissions = AdminPermissions.inclusions("admin:list")
    assert permissions == ["*:*", "admin:*", "admin:create", "admin:update", "role:*", "role:assign", "admin:show", "admin:list"]
  end
end
