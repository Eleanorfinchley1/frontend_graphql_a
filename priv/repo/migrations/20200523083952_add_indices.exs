defmodule Repo.Migrations.AddIndices do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:posts, [:inserted_at])
    create_if_not_exists index(:events, [:post_id])
    create_if_not_exists index(:posts_comments, [:post_id])
    create_if_not_exists index(:posts_upvotes, [:post_id])
    create_if_not_exists index(:posts_downvotes, [:post_id])
  end
end
