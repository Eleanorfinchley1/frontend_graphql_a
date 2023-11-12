defmodule Repo.Migrations.AddUserBanned do
  use Ecto.Migration

  def change do
    alter table(:accounts_userprofile) do
      add :banned?, :boolean, default: false, null: false
    end
  end
end
