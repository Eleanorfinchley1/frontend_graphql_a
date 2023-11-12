defmodule Repo.Migrations.AddTableForBusinessCategories do
  use Ecto.Migration

  def change do
    create table(:business_categories) do
      add(:category_name, :string, null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end
  end
end
