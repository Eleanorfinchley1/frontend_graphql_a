defmodule BillBored.User.Membership do
  @moduledoc "schema for authtoken_token table"

  use BillBored, :schema
  import Ecto.Changeset
  alias BillBored.User

  @type t :: %__MODULE__{}

  schema "accounts_membership" do
    field(:role, :string)
    field(:required_approval, :boolean, default: true)

    belongs_to(:business_account, User)
    belongs_to(:member, User)

    timestamps(inserted_at: :created, updated_at: :updated)
  end

  @required_fields ~w(business_account_id member_id role)a

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, @required_fields)
  end
end
