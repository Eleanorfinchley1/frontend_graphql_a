defmodule Repo.Migrations.IndexPostsByLocation do
  use Ecto.Migration

  def change do
    create index(:posts, [:location], using: "gist")
  end
end
