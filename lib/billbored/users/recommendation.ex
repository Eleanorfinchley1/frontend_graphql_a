defmodule BillBored.User.Recommendation do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.User

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]
  @valid_types ["autofollow"]

  schema "user_recommendations" do
    field :type, :string
    belongs_to(:user, User)
    timestamps()
  end

  def changeset(recommendation, attrs) do
    recommendation
    |> cast(attrs, [:user_id, :type])
    |> validate_inclusion(:type, @valid_types)
    |> validate_required([:user_id, :type])
  end
end
