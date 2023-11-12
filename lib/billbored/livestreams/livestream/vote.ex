defmodule BillBored.Livestream.Vote do
  @moduledoc "schema for livestream_votes table"

  use BillBored, :schema
  alias BillBored.{User, Livestream}

  @type t :: %__MODULE__{}

  @primary_key false
  schema "livestream_votes" do
    belongs_to(:livestream, Livestream, type: Ecto.UUID, primary_key: true)
    belongs_to(:user, User, primary_key: true)

    field(:vote_type, :string)

    timestamps()
  end

  @required [:user_id, :livestream_id]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(vote, params \\ %{}) do
    vote
    |> cast(params, @required ++ [:vote_type])
    |> validate_required(@required)
    |> validate_inclusion(:vote_type, ["upvote", "downvote", "", nil])
    |> unique_constraint(:user_id, name: :livestream_votes_user_id_livestream_id_index)
  end
end
