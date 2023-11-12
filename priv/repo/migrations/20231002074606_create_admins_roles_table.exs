defmodule Repo.Migrations.CreateAdminsRolesTable do
  use Ecto.Migration

  def change do
    create table(:admins_roles) do
      add :admin_id, references("admins")
      add :role_id, references("admin_roles")
    end
  end
end
