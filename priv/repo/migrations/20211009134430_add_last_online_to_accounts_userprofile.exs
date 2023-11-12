defmodule Repo.Migrations.AddLastOnlineToAccountsUserprofile do
  use Ecto.Migration

  def change do
    alter table(:accounts_userprofile) do
      add :last_online_at, :timestamptz
    end
  end
end
