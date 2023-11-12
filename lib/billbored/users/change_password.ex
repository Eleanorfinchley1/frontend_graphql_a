defmodule BillBored.Users.ChangePassword do
  @moduledoc """
    This module describes the schema `change_password` and its all fields with the data types used to work with this module.

    To work with this schema, you need to use a dependency.

        use BillBored, :schema
        import Ecto.Changeset

    To work with the scheme should be declared alias and make requests to the database.

        alias BillBored.Users.ChangePassword

    Examples of features to use this module are presented in the `BillBored.Users`
  """

  use BillBored, :schema
  import Ecto.Changeset

  alias BillBored.User

  @typedoc """
    This type describes all the fields that are available in the `change_password` schema and links to other tables in the tray on the Primary key.
  """
  @type t :: %__MODULE__{
          id: integer(),
          hash: binary(),
          user_id: integer(),
          user: User.t()
        }

  schema "change_password" do
    field(:hash, :string)

    belongs_to(:user, User)

    timestamps(type: :utc_datetime_usec, inserted_at: :created, updated_at: :updated)
  end

  @doc """
    This feature shows the fields that are required to record, and you can record fields that are unique.

        def changeset(change_password, attrs) do
          change_password
          # The fields that are allowed for the record.
          |> cast(attrs, [:hash, :user_id])
          # The fields are required for recording.
          |> validate_required([:hash, :user_id])
        end
  """
  @spec changeset(__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def changeset(change_password, attrs) do
    change_password
    |> cast(attrs, [:hash, :user_id])
    |> validate_required([:hash, :user_id])
    |> unique_constraint(:id, name: :change_password_pkey, message: "must be unique")
  end
end
