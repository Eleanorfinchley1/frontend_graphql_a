defmodule BillBored.Post.Comment.Interest do
  use BillBored, :schema
  alias BillBored.{Post.Comment, Interest}

  @type t :: %__MODULE__{}

  schema "posts_comments_interests" do
    belongs_to(:comment, Comment)
    belongs_to(:interest, Interest)
  end
end
