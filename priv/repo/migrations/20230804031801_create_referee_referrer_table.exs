defmodule Repo.Migrations.CreateRefereeReferrerTable do
  use Ecto.Migration

  def change do
    create table(:accounts_referrals, primary_key: false) do
      add :referee_id, references(:accounts_userprofile), null: false
      add :referrer_id, references(:accounts_userprofile), null: false
      timestamps(updated_at: false)
    end
  end
end
