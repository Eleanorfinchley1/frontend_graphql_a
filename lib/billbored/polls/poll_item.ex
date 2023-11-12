defmodule BillBored.PollItem do
  use BillBored, :schema
  import BillBored.Helpers, only: [media_files_from_keys: 1]
  alias BillBored.{Poll, PollItem, Upload}

  @type t :: %__MODULE__{}

  schema "polls_items" do
    field(:title, :string)

    field(:user_voted?, :boolean, default: false, virtual: true)
    field(:votes_count, :integer, default: 0, virtual: true)

    has_many(:votes, PollItem.Vote)

    many_to_many :media_files, Upload,
      join_through: "poll_item_uploads",
      join_keys: [poll_item_id: :id, upload_key: :media_key],
      on_replace: :delete

    belongs_to(:poll, Poll)
  end

  def changeset(item, params \\ %{}) do
    item
    |> cast(params, [:title, :poll_id])
    |> put_assoc(:media_files, media_files_from_keys(params["media_file_keys"] || []))
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 250)
  end

  # # TODO: think of a better way
  # def normalize(%{votes_count: nil} = post) do
  #   normalize(Map.put(post, :votes_count, 0))
  # end

  # def normalize(%{user_voted?: nil} = post) do
  #   normalize(Map.put(post, :user_voted?, false))
  # end

  # def normalize(post), do: post
end
