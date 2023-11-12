defmodule Repo.Migrations.AddCascadeDeleteOnPostsInterests do
  use Ecto.Migration

  def change do
    alter table("posts_interests") do
      remove :post_id
      remove :interest_id

      add :post_id, references("posts", on_delete: :delete_all)
      add :interest_id, references("interests", on_delete: :delete_all)
    end
  end
end
