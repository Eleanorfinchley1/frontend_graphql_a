defmodule BillBored.PollItem.Vote do
  use BillBored, :schema

  alias BillBored.{PollItem, User}

  @type t :: %__MODULE__{}

  schema "polls_items_votes" do
    belongs_to :poll_item, PollItem
    belongs_to :user, User

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end
end
