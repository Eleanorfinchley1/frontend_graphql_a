defmodule Repo.Migrations.AddTableForBusinessAccountsRelationship do
  use Ecto.Migration

  def change do
    create table(:accounts_membership) do
      add(:business_account_id, references(:accounts_userprofile, on_delete: :delete_all),
        null: false
      )

      add(:member_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:role, :string, null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create(unique_index(:accounts_membership, [:business_account_id, :member_id]))
  end
end
