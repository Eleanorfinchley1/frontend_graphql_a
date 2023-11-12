defmodule BillBored.Invites.Invite do
  @moduledoc """
    This module describes the schema `accounts_invites` and its all fields with the data types used to work with this module.

    To work with this schema, you need to use a dependency.

        use BillBored, :schema
        import Ecto.Changeset

    To work with the scheme should be declared alias and make requests to the database.

        BillBored.Invites.Invite

    Examples of features to use this module are presented in the `BillBored.Invites`
  """

  use BillBored, :schema
  import Ecto.Changeset

  @typedoc """
    This type describes all the fields that are available in the `accounts_invites` schema and links to other tables in the tray on the Primary key.
  """
  @type t :: %__MODULE__{
          id: integer(),
          email: String.t(),
          user_id: integer(),
          created: timeout(),
          user: BillBored.User.t()
        }

  schema "accounts_invites" do
    field(:email, :string)

    belongs_to(:user, BillBored.User)

    timestamps(inserted_at: :created, updated_at: false)
  end

  @doc """
    This feature shows the fields that are required to record, and you can record fields that are unique.

        def changeset(invite, attrs) do
          invite
          # The fields that are allowed for the record.
          |> cast(attrs, [:email, :user_id])
          # The fields are required for recording.
          |> validate_required([:email, :user_id])
        end
  """
  @spec changeset(__MODULE__.t(), map()) :: Ecto.Changeset.t()
  def changeset(invite, attrs) do
    invite
    |> cast(attrs, [:email, :user_id])
    |> validate_required([:email, :user_id])
    |> unique_constraint(:user_id_email)
  end
end
