defmodule Repo.Migrations.CreateMenteeTable do
  use Ecto.Migration

  def up do
    create table("mentor_mentee", primary_key: false) do
      add :mentor_id, references("mentor", column: :mentor_id, on_delete: :delete_all), primary_key: true

      add :user_id,
          references("accounts_userprofile", on_delete: :delete_all), primary_key: true
    end

    create unique_index(:mentor_mentee, [:user_id, :mentor_id])
  end

  def down do
    drop table("mentor_mentee")
  end
end
