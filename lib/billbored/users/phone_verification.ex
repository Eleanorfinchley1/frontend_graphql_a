# TODO what's the point of this module?
defmodule BillBored.Users.PhoneVerification do
  # TODO it's not virtual
  @moduledoc "virtual schema for phone verification"

  use BillBored, :schema

  @type t :: %__MODULE__{}

  @primary_key false
  schema "phone_verification" do
    field(:otp, :string)
  end
end
