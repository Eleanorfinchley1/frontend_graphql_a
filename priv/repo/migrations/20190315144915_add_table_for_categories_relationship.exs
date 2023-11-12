defmodule Repo.Migrations.AddTableForCategoriesRelationShip do
  use Ecto.Migration

  def change do
    create table(:businesses_categories) do
      add(:business_category_id, references(:business_categories), null: false)
      add(:user_id, references(:accounts_userprofile), null: false)
    end
  end

  def down do
    execute("DROP TABLE businesses_categories")
  end
end
