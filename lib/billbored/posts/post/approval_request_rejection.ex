defmodule BillBored.Post.ApprovalRequest.Rejection do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias BillBored.{Post, User}

  @type t :: %__MODULE__{}

  @primary_key false
  schema "post_approval_request_rejection" do
    belongs_to(:approver, User, primary_key: true)
    belongs_to(:post, Post, primary_key: true)
    belongs_to(:requester, User, primary_key: true)
    field(:note, :string)
    timestamps(type: :naive_datetime_usec)
  end

  def changeset(rejection, attrs) do
    cast(rejection, attrs, [:note])
  end
end
