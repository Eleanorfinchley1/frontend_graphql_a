defmodule Repo.Migrations.CreateCovidLocations do
  use Ecto.Migration

  def up do
    drop(table(:covid_cases))

    create(table(:covid_locations)) do
      add :country_code, :string, null: false
      add :scope, :string, null: false
      add :country, :string
      add :state, :string
      add :county, :string
      add :city, :string
      add :region, :string, null: false
      add :source_population, :integer
      add :population, :integer
      add :source_location, :geography
      add :location, :geography
    end

    create(index(:covid_locations, [:scope, :country_code, :region], unique: true, name: :covid_locations_uniq_idx))

    create(table(:covid_cases)) do
      add :datetime, :utc_datetime_usec, null: false
      add :timeslot, :integer, null: false
      add :location_id, references(:covid_locations)
      add :source_url, :text
      add :cases, :integer, null: false
      add :deaths, :integer
      add :recoveries, :integer
      add :active_cases, :integer
    end

    create(index(:covid_cases, [:datetime]))
    create(index(:covid_cases, [:timeslot, :location_id], unique: true, name: :covid_cases_uniq_idx))
  end

  def down do
    drop(table(:covid_cases))
    drop(table(:covid_locations))

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
