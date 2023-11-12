defmodule BillBored.Users.Referral do
  use BillBored, :schema

  alias BillBored.User

  @primary_key false
  schema "accounts_referrals" do
    belongs_to(:referee, User, foreign_key: :referee_id, primary_key: true)
    belongs_to(:referrer, User, foreign_key: :referrer_id, primary_key: true)

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(referral, attrs) do
    referral
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required([:referee_id, :referrer_id])
    |> unique_constraint([:referee_id, :referrer_id], name: "referee_referrer_pkey")
    |> unique_constraint([:referrer_id, :referee_id], name: "referrer_referee_index")
    |> foreign_key_constraint(:referee_id)
    |> foreign_key_constraint(:referrer_id)
  end
end
