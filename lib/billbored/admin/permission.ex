defmodule BillBored.AdminPermission do
  @permissions %{
    "*:*" => %{
      label: "All"
    },
    "admin:*" => %{
      label: "Manage the admin accounts",
      included: ["*:*"]
    },
    "admin:create" => %{
      label: "Register new admin account",
      included: ["admin:*"]
    },
    "admin:update" => %{
      label: "Edit/Ban/Reset admin account",
      included: ["admin:*"]
    },
    "admin:show" => %{
      label: "View admin account's details",
      included: ["admin:update", "role:assign"]
    },
    "admin:list" => %{
      label: "View admin accounts",
      included: ["admin:create", "admin:show"]
    },
    "role:*" => %{
      label: "Manage roles",
      included: ["*:*"]
    },
    "role:create" => %{
      label: "Create role",
      included: ["role:*"]
    },
    "role:update" => %{
      label: "Edit role",
      included: ["role:*"]
    },
    "role:delete" => %{
      label: "Delete role",
      included: ["role:*"]
    },
    "role:show" => %{
      label: "View a role in details",
      included: ["role:update"]
    },
    "role:list" => %{
      label: "View roles",
      included: ["role:create", "role:show", "role:delete"]
    },
    "role:assign" => %{
      label: "Assign role to admin account",
      included: ["role:*", "admin:*"]
    },
    "post:*" => %{
      label: "Manage posts",
      included: ["*:*"]
    },
    "post:create" => %{
      label: "Create a post",
      included: ["post:*"]
    },
    "post:update" => %{
      label: "Update a post",
      included: ["post:*"]
    },
    "post:delete" => %{
      label: "Delete a post",
      included: ["post:*"]
    },
    "post:show" => %{
      label: "View a post in details",
      included: ["post:update"]
    },
    "post:list" => %{
      label: "View posts",
      included: ["post:create", "post:show", "post:delete"]
    },
    "interest:*" => %{
      label: "Manage interests",
      included: ["*:*"]
    },
    "interest:create" => %{
      label: "Create an interest",
      included: ["interest:*"]
    },
    "interest:update" => %{
      label: "Update an interest",
      included: ["interest:*"]
    },
    "interest:delete" => %{
      label: "Delete an interest",
      included: ["interest:*"]
    },
    "interest:show" => %{
      label: "View an interest in details",
      included: ["interest:update"]
    },
    "interest:list" => %{
      label: "View interests",
      included: ["interest:create", "interest:show", "interest:delete"]
    }
  }

  def all_permissions, do: @permissions
end
