defmodule Repo.Migrations.AddEventCategories do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add(:categories, {:array, :string}, default: [])
    end

    create(index(:events, [:categories], using: "GIN"))
  end
end
