defmodule BillBored.User.Feedback do
  @moduledoc "schema for appnotifications_device table"

  use BillBored, :schema
  use Scrivener
  alias BillBored.{User, Feedback}

  @type t :: %__MODULE__{}

  @primary_key false
  schema "accounts_userfeedback" do
    field(:rating, :decimal)

    belongs_to(:feedback, Feedback, primary_key: true, foreign_key: :feedback_ptr_id)
    belongs_to(:user, User)
  end

  @doc false
  def changeset(userfeedback, attrs) do
    userfeedback
    |> cast(attrs, [
      :rating,
      :user_id,
      :feedback_ptr_id
    ])
    |> validate_required([:rating, :user_id, :feedback_ptr_id])
    |> unique_constraint(:user_id_feedback_id, name: :accounts_userfeedback_pkey)
  end
end
