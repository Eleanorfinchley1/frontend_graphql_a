defmodule BillBored.Admin.Role do
  use BillBored, :schema

  import Ecto.Changeset

  alias BillBored.{Admin, AdminRole}

  @type t :: %__MODULE__{}

  schema "admins_roles" do
    belongs_to(:admin, Admin, foreign_key: :admin_id)
    belongs_to(:role, AdminRole, foreign_key: :role_id)
  end

  @required_fields ~w(admin_id role_id)a
  @optional_fields ~w()a

  @doc false
  def create_changeset(admin_role, attrs \\ %{}) do
    admin_role
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def update_changeset(admin_role, attrs \\ %{}) do
    admin_role
    |> cast(attrs, @required_fields ++ @optional_fields)
  end
end
