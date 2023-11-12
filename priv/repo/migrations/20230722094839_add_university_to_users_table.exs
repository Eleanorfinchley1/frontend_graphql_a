defmodule Repo.Migrations.AddUniversityToUsersTable do
  use Ecto.Migration

  def change do
    alter table "accounts_userprofile" do
      add :university_id, references("university")
    end
  end
end
