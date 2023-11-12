defmodule Repo.Migrations.AddUniqueIndexInMentorMentee do
  use Ecto.Migration

  def change do
    create unique_index(:mentor_mentee, [:user_id])
  end
end
