defmodule Repo.Migrations.CreateAdminRolesTable do
  use Ecto.Migration

  def change do
    create table(:admin_roles) do
      add :label, :string, null: false
      add :permissions, {:array, :string}, null: false, default: []
    end

    create index(:admin_roles, [:label], unique: true)
  end
end
