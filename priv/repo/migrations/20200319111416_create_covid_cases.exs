defmodule Repo.Migrations.CreateCovidCases do
  use Ecto.Migration

  def change do
    create(table(:covid_cases)) do
      add :datetime, :utc_datetime_usec, null: false
      add :location, :geography, null: false
      add :source_url, :text
      add :country_code, :string, null: false
      add :country, :string
      add :scope, :string
      add :region, :string
      add :cases, :integer, null: false
      add :deaths, :integer
      add :recoveries, :integer
      add :active_cases, :integer
      add :population, :integer
    end

    create(index(:covid_cases, [:datetime]))
    create(index(:covid_cases, ["date_trunc('day', datetime)", :country_code, :scope, :region], unique: true, name: :covid_cases_uniq_idx))
  end
end
