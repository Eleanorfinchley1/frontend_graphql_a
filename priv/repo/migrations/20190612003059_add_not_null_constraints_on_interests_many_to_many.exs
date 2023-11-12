defmodule Repo.Migrations.AddNotNullConstraintsOnInterestsManyToMany do
  use Ecto.Migration

  def change do
    alter table("posts_interests") do
      remove :post_id
      remove :interest_id

      add :post_id, references("posts", on_delete: :delete_all), null: false
      add :interest_id, references("interests", on_delete: :delete_all), null: false
    end

    alter table("posts_comments_interests") do
      remove :comment_id
      remove :interest_id

      add :comment_id, references("posts_comments", on_delete: :delete_all), null: false
      add :interest_id, references("interests", on_delete: :delete_all), null: false
    end
  end
end
