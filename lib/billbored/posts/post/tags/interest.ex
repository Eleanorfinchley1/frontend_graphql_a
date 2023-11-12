defmodule BillBored.Post.Interest do
  use BillBored, :schema
  alias BillBored.{Post, Interest}

  @type t :: %__MODULE__{}

  schema "posts_interests" do
    belongs_to(:post, Post)
    belongs_to(:interest, Interest)
  end
end
