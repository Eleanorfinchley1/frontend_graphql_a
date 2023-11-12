defmodule Repo.Migrations.CreateInterestsCategories do
  use Ecto.Migration

  def change do
    create(table(:interest_categories)) do
      add :name, :string
      timestamps()
    end

    create(table(:interest_categories_interests)) do
      add :interest_category_id, references(:interest_categories)
      add :interest_id, references(:interests)
    end

    create(index(:interest_categories, [:name], unique: true))
    create(index(:interest_categories_interests, [:interest_category_id, :interest_id], unique: true))
  end
end
