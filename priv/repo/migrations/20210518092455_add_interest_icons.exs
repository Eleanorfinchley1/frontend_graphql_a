defmodule Repo.Migrations.AddInterestIcons do
  use Ecto.Migration

  def change do
    alter(table(:interest_categories)) do
      add :icon, :string
    end

    alter(table(:interests)) do
      add :icon, :string
    end
  end
end
