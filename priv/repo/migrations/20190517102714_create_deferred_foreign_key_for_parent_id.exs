defmodule Repo.Migrations.CreateDeferredForeignKeyForParentId do
  use Ecto.Migration

  def change do
    execute(
      "ALTER TABLE comments_comments DROP CONSTRAINT comments_comments_parent_id_d9fe1944_fk_comments_comments_id"
    )

    alter table(:comments_comments) do
      modify(:parent_id, references(:comments_comments))
    end
  end
end
