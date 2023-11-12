defmodule Repo.Migrations.AddLevelIntoMentor do
  use Ecto.Migration

  def change do
    alter table(:mentor) do
      add :level, :integer, default: 1
    end
  end
end
