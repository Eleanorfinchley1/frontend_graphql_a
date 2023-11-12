defmodule Repo.Migrations.AddConstraintsInterests do
  use Ecto.Migration

  def change do
    create unique_index(:interests, [:hashtag])
  end
end
