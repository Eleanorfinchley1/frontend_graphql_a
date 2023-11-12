defmodule Repo.Migrations.MakeUserPhoneNullable do
  use Ecto.Migration

  def up do
    alter table(:accounts_userprofile) do
      modify :phone, :text, null: true
    end
  end

  def down do
    alter table(:accounts_userprofile) do
      modify :phone, :string, null: false, size: 12
    end
  end
end
