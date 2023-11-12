defmodule BillBored.User.Device do
  @moduledoc "schema for appnotifications_device table"

  use BillBored, :schema
  alias BillBored.User

  @type t :: %__MODULE__{}

  schema "appnotifications_device" do
    field(:token, :string)

    # supposedly, "ios" or "android" or "windows" or ""
    field(:platform, :string)
    belongs_to(:user, User)

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [
      :token,
      :user_id,
      :platform
    ])
    |> validate_required([:token, :user_id])
    |> unique_constraint(:token, name: :appnotifications_device_token_6765efeb_uniq)
  end
end
