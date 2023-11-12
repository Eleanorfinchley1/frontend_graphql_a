defmodule Repo.Migrations.CreateTablePostsAndRelated do
  use Ecto.Migration

  def change do
    #    drop_if_exists table("poll_items")
    #    drop_if_exists table("poll")

    create table("posts") do
      add :type, :string, size: 10, null: false

      # to be altered in future:
      add :author_id, references("accounts_userprofile"), null: false

      add :title, :string, size: 512
      add :body, :text
      add :location, :geometry, null: false
      add :fake_location, :geometry

      add :parent_id, references("posts")
      add :place_id, references("places")

      add :post_cost, :integer

      add :private?, :boolean, default: false

      add :media_file_keys, {:array, :string}, default: []

      # to be changed in future:
      add :business_admin_id, references("accounts_userprofile")
      add :business_id, references("accounts_userprofile")
      add :business_name, :string

      timestamps()
    end

    create table("polls") do
      add :question, :text, null: false
      add :post_id, references("posts"), null: false

      timestamps()
    end

    create table("polls_items") do
      add :title, :string, null: false, size: 512
      add :media_file_keys, {:array, :string}, default: []

      add :poll_id, references("polls"), null: false
    end

    create table("posts_interests") do
      add :post_id, references("posts"), null: false
      add :interest_id, references("interests"), null: false
    end

    create table("posts_comments") do
      add :post_id, references("posts"), null: false

      # to be changed in future:
      add :author_id, references("accounts_userprofile"), null: false

      add :comment, :text, null: false, default: ""

      add :disabled?, :boolean, default: false
      add :media_file_keys, {:array, :string}, default: []

      add :parent_id, references("posts_comments")

      timestamps()
    end
  end
end
