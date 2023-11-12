defmodule Repo.Migrations.CreateTablePostsCommentsUpvotesAndDownvotes do
  use Ecto.Migration

  def change do
    create table("posts_comments_upvotes") do
      add :user_id, references("accounts_userprofile", on_delete: :delete_all), null: false
      add :comment_id, references("posts_comments", on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create table("posts_comments_downvotes") do
      add :user_id, references("accounts_userprofile", on_delete: :delete_all), null: false
      add :comment_id, references("posts_comments", on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    drop table("posts_downvotes")
    drop table("posts_upvotes")

    create table("posts_upvotes") do
      add :user_id, references("accounts_userprofile", on_delete: :delete_all), null: false
      add :post_id, references("posts", on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end

    create table("posts_downvotes") do
      add :user_id, references("accounts_userprofile", on_delete: :delete_all), null: false
      add :post_id, references("posts", on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end
  end
end
