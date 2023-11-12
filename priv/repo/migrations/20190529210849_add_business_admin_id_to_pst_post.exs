defmodule Repo.Migrations.AddBusinessAdminIdToPstPost do
  use Ecto.Migration

  def change do
    alter table(:pst_post) do
      add :business_admin_id, references(:accounts_userprofile)
    end
  end
end
