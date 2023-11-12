defmodule Repo.Migrations.AddAdminAuthorIdIntoPosts do
  use Ecto.Migration

  def change do
    drop_if_exists constraint(:posts, :posts_author_id_fkey)

    alter table(:posts) do
      add :admin_author_id, references(:admins), null: true
      modify :author_id, references(:accounts_userprofile), null: true
    end
  end
end
