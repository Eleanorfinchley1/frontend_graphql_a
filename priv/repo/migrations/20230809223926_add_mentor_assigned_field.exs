defmodule Repo.Migrations.AddMentorAssignedField do
  use Ecto.Migration

  def change do
    alter table("mentor_mentee") do
      add :mentor_assigned, :utc_datetime_usec, default: fragment("now()")
    end

  end
end
