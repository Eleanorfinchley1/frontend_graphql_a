defmodule BillBored.Post.ApprovalRequest do
  @moduledoc false

  use Ecto.Schema
  alias BillBored.{Post, User}

  @type t :: %__MODULE__{}

  @primary_key false
  schema "post_approval_request" do
    belongs_to(:approver, User, primary_key: true)
    belongs_to(:post, Post, primary_key: true)
    belongs_to(:requester, User, primary_key: true)
    timestamps(type: :naive_datetime_usec)
  end
end
