defmodule Repo.Migrations.CreateAdminsTable do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE admin_account_status AS ENUM ('pending', 'expired', 'accepted', 'enabled', 'banned')")

    create table(:admins) do
      add :username, :string, null: false
      add :email, :string, null: false
      add :password, :string, null: false
      add :first_name, :string, null: true
      add :last_name, :string, null: true
      add :university_id, references("university")
      add :status, :admin_account_status, null: false, default: "pending"

      timestamps()
    end

    create index(:admins, [:username], unique: true)
    create index(:admins, [:email], unique: true)
  end
end
