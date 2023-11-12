defmodule BillBored.Post.UserTag do
  @moduledoc "schema for pst_post_usertags table"

  use BillBored, :schema
  alias BillBored.{Post, User}

  @type t :: %__MODULE__{}

  schema "pst_post_usertags" do
    belongs_to(:user, User, foreign_key: :userprofile_id)
    belongs_to(:post, Post)
  end
end
