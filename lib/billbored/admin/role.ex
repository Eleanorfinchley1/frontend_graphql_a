defmodule BillBored.AdminRole do
  use BillBored, :schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
            only: [
              :id,
              :label,
              :permissions
            ]}
  schema "admin_roles" do
    field(:label, :string)
    field(:permissions, {:array, :string})
  end

  @required_fields ~w(label)a
  @optional_fields ~w(permissions)a

  @doc false
  def create_changeset(role, attrs \\ %{}) do
    role
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:label, name: :admin_roles_label_index, message: "is already taken by other role.")
  end

  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> unique_constraint(:label, name: :admin_roles_label_index, message: "is already taken by other role.")
  end
end
