defmodule BillBored.Post.Downvote do
  use BillBored, :schema
  alias BillBored.{User, Post}

  @type t :: %__MODULE__{}

  schema "posts_downvotes" do
    belongs_to(:user, User)
    belongs_to(:post, Post)

    timestamps inserted_at: :inserted_at, updated_at: false
  end
end
