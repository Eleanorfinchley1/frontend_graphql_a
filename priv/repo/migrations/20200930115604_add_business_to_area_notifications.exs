defmodule Repo.Migrations.AddBusinessToAreaNotifications do
  use Ecto.Migration

  def change do
    alter table(:area_notifications) do
      add :business_id, references(:accounts_userprofile)
    end

    create index(:area_notifications, [:inserted_at])
  end
end
