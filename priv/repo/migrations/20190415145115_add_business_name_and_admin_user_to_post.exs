defmodule Repo.Migrations.AddBusinessNameAndAdminUserToPost do
  use Ecto.Migration

  def change do
    alter table(:pst_post) do
      add(:business_username, :string)
      add(:admin_username, :string)
    end
  end
end
