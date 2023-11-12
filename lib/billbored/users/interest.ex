defmodule BillBored.User.Interest do
  use BillBored, :schema

  alias BillBored.{User, Interest}

  @type t :: %__MODULE__{}

  schema "interests_userinterest" do
    field(:rating, :integer, default: 0)

    belongs_to(:user, User)
    belongs_to(:interest, Interest)

    timestamps(inserted_at: :created, updated_at: :updated)
  end

  def changeset(user_interest, attrs) do
    user_interest
    |> cast(attrs, [:rating, :user_id, :interest_id])
    |> validate_required([:user_id, :interest_id])
    |> unique_constraint(:user_id_interest_id)
  end
end
