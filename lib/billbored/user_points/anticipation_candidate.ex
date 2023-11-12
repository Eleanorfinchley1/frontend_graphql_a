defmodule BillBored.AnticipationCandidate do
  @moduledoc "schema for anticipaton_candidates table"

  use BillBored, :schema
  use BillBored.User.Blockable, foreign_key: :user_id

  alias BillBored.User

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
  only: [
    :user_id,
    :topic,
    :rewarded,
    :expire_at,
    :inserted_at
  ]}

  schema "anticipaton_candidates" do
    field(:topic, :string)
    field(:expire_at, :utc_datetime_usec)
    field(:rewarded, :boolean)

    belongs_to(:user, User, foreign_key: :user_id)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  @castable [:topic, :user_id, :expire_at, :rewarded]
  @required [:topic, :user_id, :expire_at]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(candidate, attrs) do
    candidate
    |> cast(attrs, @castable)
    |> validate_required(@required)
  end
end
