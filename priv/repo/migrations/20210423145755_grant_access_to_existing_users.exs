defmodule Repo.Migrations.GrantAccessToExistingUsers do
  use Ecto.Migration

  def up do
    execute("UPDATE accounts_userprofile SET flags = flags || jsonb_build_object('access', 'granted');")
  end

  def down do
  end
end
