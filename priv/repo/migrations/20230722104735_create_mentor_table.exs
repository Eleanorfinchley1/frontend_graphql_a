defmodule Repo.Migrations.AddMentorTable do
  use Ecto  .Migration

  def up do
    create table("mentor", primary_key: false) do
      add :mentor_id,
          references("accounts_userprofile", on_delete: :delete_all), primary_key: true
    end
  end

  def down do
    drop table("mentor")
  end
end
