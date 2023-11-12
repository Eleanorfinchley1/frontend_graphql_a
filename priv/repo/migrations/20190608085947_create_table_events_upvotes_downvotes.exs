defmodule Repo.Migrations.CreateTableEventsUpvotesDownvotes do
  use Ecto.Migration

  def change do
    create table("posts_events") do
      add :post_id, references("posts"), null: false
      add :date, :utc_datetime_usec, null: false
      add :location, :geometry, null: false
      add :title, :string, null: false
      add :media_file_keys, {:array, :string}, default: []

      timestamps()
    end

    create table("posts_upvotes") do
      add :user_id, references("accounts_userprofile"), null: false
      add :post_id, references("posts"), null: false

      timestamps()
    end

    create table("posts_downvotes") do
      add :user_id, references("accounts_userprofile"), null: false
      add :post_id, references("posts"), null: false

      timestamps()
    end
  end
end
