defmodule Repo.Migrations.AddInsertedAtToUserFollows do
  use Ecto.Migration

  def up do
    alter table(:accounts_userprofile_follows) do
      add(:inserted_at, :timestamptz, null: true)
    end

    execute "UPDATE accounts_userprofile_follows SET inserted_at = NOW()"

    alter table(:accounts_userprofile_follows) do
      modify(:inserted_at, :timestamptz, null: false)
    end
  end

  def down do
    alter table(:accounts_userprofile_follows) do
      remove(:inserted_at)
    end
  end
end
