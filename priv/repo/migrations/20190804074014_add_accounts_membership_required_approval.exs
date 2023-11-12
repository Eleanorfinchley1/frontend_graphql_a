defmodule Repo.Migrations.AddAccountsMembershipRequiredApproval do
  use Ecto.Migration

  def change do
    alter table(:accounts_membership) do
      add(:required_approval, :boolean, default: true)
    end
  end
end
