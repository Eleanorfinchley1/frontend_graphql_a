defmodule BillBored.Post.Comment.Upvote do
  use BillBored, :schema
  alias BillBored.{User, Post}

  @type t :: %__MODULE__{}

  schema "posts_comments_upvotes" do
    belongs_to(:user, User)
    belongs_to(:comment, Post.Comment)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end
end
