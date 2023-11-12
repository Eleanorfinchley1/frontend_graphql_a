defmodule Repo.Migrations.AddOnDeleteAllForTheParentIdReferences do
  use Ecto.Migration

  def change do
    drop constraint("posts", "posts_parent_id_fkey")
    drop constraint("posts_comments", "posts_comments_parent_id_fkey")

    alter table("posts") do
      modify :parent_id, references("posts", on_delete: :delete_all)
    end

    alter table("posts_comments") do
      modify :parent_id, references("posts_comments", on_delete: :delete_all)
    end
  end
end
