defmodule BillBored.User.AuthToken do
  @moduledoc "schema for authtoken_token table"

  use BillBored, :schema
  import Ecto.Changeset
  alias BillBored.User

  @type t :: %__MODULE__{}

  @primary_key false
  schema "authtoken_token" do
    field(:key, :string)
    belongs_to(:user, User)

    timestamps(updated_at: false)
  end

  @required_fields ~w(key user_id)a

  @doc false
  def changeset(auth_token, attrs) do
    auth_token
    |> cast(attrs, @required_fields)
  end
end
