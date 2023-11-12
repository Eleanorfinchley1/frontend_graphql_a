defmodule Repo.Migrations.AddBusinessToUsersAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts_userprofile) do
      add(:is_business, :boolean, default: false, null: false)
    end
  end

  def down do
    alter table(:accounts_userprofile) do
      remove(:is_business)
    end
  end
end
