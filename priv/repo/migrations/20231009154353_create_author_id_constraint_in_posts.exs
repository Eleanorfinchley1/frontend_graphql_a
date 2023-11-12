defmodule Repo.Migrations.CreateAuthorIdConstraintInPosts do
  use Ecto.Migration

  def change do
    create(
      constraint(
        :posts,
        :validate_author_id,
        check: "num_nonnulls(author_id, admin_author_id) = 1"
      )
    )
  end
end
