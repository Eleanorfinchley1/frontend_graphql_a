defmodule Repo.Migrations.RenameColumnOnPostsComments do
  use Ecto.Migration

  def change do
    rename table("posts_comments"), :comment, to: :body
  end
end
