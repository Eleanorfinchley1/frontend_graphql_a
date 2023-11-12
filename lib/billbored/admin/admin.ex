defmodule BillBored.Admin do
  use BillBored, :schema

  import Ecto.Changeset
  import Bcrypt, only: [hash_pwd_salt: 1]

  alias BillBored.{University, AdminRole}

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder,
           only: [
             :id,
             :username,
             :first_name,
             :last_name,
             :email,
             :status,
             :university_id,
             :inserted_at,
             :updated_at
           ]}
  schema "admins" do
    field(:email, :string)
    field(:password, :string)
    field(:username, :string, default: "")
    field(:first_name, :string, default: "")
    field(:last_name, :string, default: "")
    field(:status, :string, default: "pending")
    field(:permissions, {:array, :string}, virtual: true)

    belongs_to(:university, University, foreign_key: :university_id)
    many_to_many(
      :roles,
      AdminRole,
      join_through: __MODULE__.Role,
      join_keys: [admin_id: :id, role_id: :id]
    )

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  @required_fields ~w(username password email)a
  @optional_fields ~w(first_name last_name university_id status)a

  @doc false
  def create_changeset(admin, attrs \\ %{}) do
    admin
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required_username()
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:university_id)
    |> encrypt_password()
    |> default_values()
    |> unique_constraint(:username, name: :admins_username_index, message: "is already taken by other.")
    |> unique_constraint(:email, name: :admins_email_index, message: "is already taken by other.")
  end

  def update_changeset(admin, attrs \\ %{}) do
    admin
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> encrypt_password()
    |> unique_constraint(:username, name: :admins_username_index, message: "is already taken by other.")
    |> unique_constraint(:email, name: :admins_email_index, message: "is already taken by other.")
  end

  defp validate_required_username(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, data: %{username: _username}} ->
        changeset

      _ ->
        put_change(changeset, :username, get_random_username())
    end
  end

  defp get_random_username(size \\ 10) do
    alphabets = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    numbers = "0123456789"

    list =
      [alphabets, String.downcase(alphabets), numbers]
      |> IO.iodata_to_binary()
      |> String.split("", trim: true)

    1..size
    |> Enum.reduce([], fn _, acc -> [Enum.random(list) | acc] end)
    |> Enum.join("")
  end

  defp default_values(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true} ->
        changeset
        |> check_for_change_default(:first_name, "")
        |> check_for_change_default(:last_name, "")
        |> check_for_change_default(:status, "pending")

      _ ->
        changeset
    end
  end

  defp check_for_change_default(changeset, field, default) do
    if get_change(changeset, field) == nil do
      put_change(changeset, field, default)
    else
      changeset
    end
  end

  # encrypt password using BCrypt
  defp encrypt_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password, hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
