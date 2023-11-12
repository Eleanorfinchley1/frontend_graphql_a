defmodule Repo.Migrations.ChangeUserPhoneUniqIndex do
  use Ecto.Migration

  def up do
    execute("UPDATE accounts_userprofile SET verified_phone = NULL WHERE verified_phone = ''")

    drop_if_exists constraint(:accounts_userprofile, :accounts_userprofile_phone_8e09b259_uniq)
    create index(:accounts_userprofile, [:country_code, :verified_phone], unique: true, name: :accounts_userprofile_phone_8e09b259_uniq)
    execute("ALTER TABLE accounts_userprofile ADD CONSTRAINT accounts_userprofile_phone_8e09b259_uniq UNIQUE USING INDEX accounts_userprofile_phone_8e09b259_uniq")
  end

  def down do
    drop_if_exists constraint(:accounts_userprofile, :accounts_userprofile_phone_8e09b259_uniq)
    create index(:accounts_userprofile, [:country_code, :phone], unique: true, name: :accounts_userprofile_phone_8e09b259_uniq)
    execute("ALTER TABLE accounts_userprofile ADD CONSTRAINT accounts_userprofile_phone_8e09b259_uniq UNIQUE USING INDEX accounts_userprofile_phone_8e09b259_uniq")
  end
end
