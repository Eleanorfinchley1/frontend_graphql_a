defmodule Repo.Migrations.CreateTablePostsCommentsInterests do
  use Ecto.Migration

  def change do
    create table("posts_comments_interests") do
      add :comment_id, references("posts_comments"), null: false
      add :interest_id, references("interests"), null: false
    end
  end
end
