defmodule Repo.Migrations.CreatePgTrgmExtension do
  use Ecto.Migration

  def up do
    execute("create extension if not exists pg_trgm;")
  end

  def down do
    execute("drop extension if exists pg_trgm;")
  end
end
