defmodule Repo.Migrations.DropUpdatedAtInterests do
  use Ecto.Migration

  def change do
    alter table("interests") do
      remove :updated_at
    end
  end
end
