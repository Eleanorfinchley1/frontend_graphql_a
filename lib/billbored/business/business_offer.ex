defmodule BillBored.BusinessOffer do
  use BillBored, :schema

  alias BillBored.{Post, User}

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "business_offers" do
    field(:discount, :string)
    field(:discount_code, :string)
    field(:business_address, :string)
    field(:qr_code, :string)
    field(:bar_code, :string)
    field(:expires_at, :utc_datetime_usec)

    belongs_to(:post, Post)
    belongs_to(:business, User)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  def changeset(%__MODULE__{} = business_offer, attrs) do
    business_offer
    |> cast(attrs, [
      :business_id,
      :post_id,
      :discount,
      :discount_code,
      :business_address,
      :qr_code,
      :bar_code,
      :expires_at
    ])
    |> validate_required([:business_id, :expires_at])
    |> validate_length(:discount_code, max: 64)
    |> validate_length(:business_address, max: 512)
    |> foreign_key_constraint(:business_id)
    |> foreign_key_constraint(:post_id)
  end
end
