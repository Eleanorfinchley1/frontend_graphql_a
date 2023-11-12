defmodule BillBored.Livestream.View do
  @moduledoc "schema for livestream_views table"

  use BillBored, :schema
  alias BillBored.{User, Livestream}

  @type t :: %__MODULE__{}

  @primary_key false
  schema "livestream_views" do
    belongs_to(:livestream, Livestream, type: Ecto.UUID, primary_key: true)
    belongs_to(:user, User, primary_key: true)

    timestamps()
  end

  @required [:user_id, :livestream_id]

  @spec changeset(t, BillBored.attrs()) :: Ecto.Changeset.t()
  def changeset(view, params \\ %{}) do
    view
    |> cast(params, @required)
    |> validate_required(@required)
    |> unique_constraint(:user_id, name: :livestream_views_user_id_livestream_id_index)
  end
end
