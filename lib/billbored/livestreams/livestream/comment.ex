defmodule BillBored.Livestream.Comment do
  @moduledoc "schema for livestream_comments table"

  use BillBored, :schema
  alias BillBored.{User, Livestream}

  @type t :: %__MODULE__{}

  schema "livestream_comments" do
    field(:body, :string)

    belongs_to(:author, User)
    belongs_to(:livestream, Livestream, type: Ecto.UUID)
    has_many(:votes, __MODULE__.Vote)

    timestamps()
  end

  @castable [:body]
  @required [:author_id, :livestream_id] ++ @castable

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, @castable)
    |> validate_required(@required)
  end
end
