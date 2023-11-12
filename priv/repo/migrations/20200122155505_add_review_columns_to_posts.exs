defmodule Repo.Migrations.AddReviewColumnsToPosts do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE posts_review_status AS ENUM ('pending', 'rejected', 'accepted')")

    alter table(:posts) do
      add :hidden?, :boolean, default: false, null: false
      add :review_status, :posts_review_status
      add :last_reviewed_at, :utc_datetime_usec, precision: 0
    end
  end

  def down do
    alter table(:posts) do
      remove :hidden?
      remove :review_status
      remove :last_reviewed_at
    end

    execute("DROP TYPE posts_review_status")
  end
end
