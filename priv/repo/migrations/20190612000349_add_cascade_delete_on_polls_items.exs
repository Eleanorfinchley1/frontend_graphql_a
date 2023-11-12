defmodule Repo.Migrations.AddCascadeDeleteOnPollsItems do
  use Ecto.Migration

  def change do
    alter table("polls_items") do
      remove :poll_id
      add :poll_id, references("polls", on_delete: :delete_all)
    end
  end
end
