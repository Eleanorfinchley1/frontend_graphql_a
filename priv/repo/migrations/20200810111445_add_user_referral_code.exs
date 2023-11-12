defmodule Repo.Migrations.AddUserReferralCode do
  use Ecto.Migration

  def change do
    alter table("accounts_userprofile") do
      add :referral_code, :string
    end
  end
end
