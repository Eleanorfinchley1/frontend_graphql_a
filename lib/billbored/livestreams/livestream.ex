defmodule BillBored.Livestream do
  @moduledoc "schema for livestreams table"

  use BillBored, :schema
  use BillBored.User.Blockable, foreign_key: :owner_id

  alias BillBored.User

  @type t :: %__MODULE__{}

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "livestreams" do
    field(:title, :string)
    field(:location, BillBored.Geo.Point)
    field(:ended_at, :utc_datetime_usec)
    field(:active?, :boolean, default: false)
    field(:recorded?, :boolean, default: false)

    belongs_to(:owner, User)
    has_many(:comments, __MODULE__.Comment)
    has_many(:votes, __MODULE__.Vote)

    timestamps()
  end

  @castable [:title, :location, :active?, :recorded?, :ended_at]
  @required [:owner_id, :title, :location]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(livestream, attrs) do
    # TODO what title max length should be? 256?
    livestream
    |> cast(attrs, @castable)
    |> validate_required(@required)
    |> validate_length(:title, max: 100)
  end

  def available(params) do
    from(l in not_blocked(params),
      inner_join: o in assoc(l, :owner),
      where: o.banned? == false and o.deleted? == false
    )
  end
end
