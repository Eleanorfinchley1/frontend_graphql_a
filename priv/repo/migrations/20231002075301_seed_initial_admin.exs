defmodule Repo.Migrations.SeedInitialAdmin do
  use Ecto.Migration
  import Ecto.Query
  alias BillBored.{Admin, AdminRole}

  def change do
    {:ok, admin} = %Admin{}
    |> Admin.create_changeset(%{
      username: "superadmin",
      email: "developer_test@temporary.com",
      password: "PASSWORD",
      first_name: "Developer",
      last_name: "Test",
      status: "enabled"
    })
    |> Repo.insert()
    IO.inspect(admin)

    {:ok, role} = %AdminRole{}
    |> AdminRole.create_changeset(%{
      label: "Super Admin",
      permissions: ["*:*"]
    })
    |> Repo.insert()
    IO.inspect(role)

    {:ok, admin_role} = %Admin.Role{}
    |> Admin.Role.create_changeset(%{
      admin_id: admin.id,
      role_id: role.id
    })
    |> Repo.insert()
    IO.inspect(admin_role)
  end
end
