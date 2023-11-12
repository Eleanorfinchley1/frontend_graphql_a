defmodule Repo.Migrations.CreateTablePollsItemsVotes do
  use Ecto.Migration

  def change do
    create table("polls_items_votes") do
      add :poll_item_id, references("polls_items", on_delete: :delete_all), null: false
      add :user_id, references("accounts_userprofile", on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end
  end
end
