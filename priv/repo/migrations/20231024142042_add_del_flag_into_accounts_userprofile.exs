defmodule Repo.Migrations.AddDelFlagIntoAccountsUserprofile do
  use Ecto.Migration

  def change do
    alter table(:accounts_userprofile) do
      add :deleted?, :boolean, default: false, null: false
    end
  end
end
