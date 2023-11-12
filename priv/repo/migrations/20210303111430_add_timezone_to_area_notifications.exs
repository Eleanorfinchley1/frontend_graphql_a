defmodule Repo.Migrations.AddTimezoneToAreaNotifications do
  use Ecto.Migration

  def change do
    alter(table(:area_notifications)) do
      add :timezone, :string
    end
  end
end
