defmodule Repo.Migrations.CreateBusinessSuggestions do
  use Ecto.Migration

  def change do
    create(table(:business_suggestions)) do
      add :business_id, references(:accounts_userprofile)
      add :suggestion, :string
      add :inserted_at, :timestamptz
      add :updated_at, :timestamptz
    end
  end
end
