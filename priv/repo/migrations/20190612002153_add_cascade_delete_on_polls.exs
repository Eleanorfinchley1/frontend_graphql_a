defmodule Repo.Migrations.AddCascadeDeleteOnPolls do
  use Ecto.Migration

  def change do
    alter table("polls") do
      remove :post_id
      add :post_id, references("posts", on_delete: :delete_all)
    end
  end
end
