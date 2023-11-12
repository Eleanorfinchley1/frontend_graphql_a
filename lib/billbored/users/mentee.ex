defmodule BillBored.Users.Mentee do
  use BillBored, :schema

  alias BillBored.User
  alias BillBored.Users.Mentor

  @primary_key false
  schema "mentor_mentee" do
    field :mentor_assigned, :utc_datetime_usec, default: DateTime.utc_now()

    belongs_to(:mentor, Mentor, references: :mentor_id, primary_key: true)
    belongs_to(:user, User, foreign_key: :user_id, primary_key: true)
  end

  def changeset(user_mentor, attrs) do
    user_mentor
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required([:user_id, :mentor_id])
    |> unique_constraint([:mentor_id, :user_id], name: "mentor_mentee_pkey")
    |> unique_constraint([:user_id, :mentor_id], name: "mentor_mentee_user_id_mentor_id_index")
    |> unique_constraint([:user_id], name: "mentor_mentee_user_id_index", message: "user has already mentor")
    |> foreign_key_constraint(:mentor_id)
    |> foreign_key_constraint(:user_id)
  end
end
