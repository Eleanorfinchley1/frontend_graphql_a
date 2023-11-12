defmodule BillBored.Users.Mentor do
  use BillBored, :schema

  alias BillBored.User
  alias BillBored.Users.Mentee

  @type t :: %__MODULE__{}

  @primary_key false
  schema "mentor" do
    # level - 1: mentor, 2: don, 3: legend
    field(:level, :integer)
    belongs_to(:user, User, foreign_key: :mentor_id, primary_key: true)
    has_many(:mentee, Mentee, foreign_key: :mentor_id, references: :mentor_id)
  end

  def changeset(user_mentor, attrs) do
    user_mentor
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required([:mentor_id])
    |> unique_constraint([:mentor_id], name: "mentor_pkey")
    |> foreign_key_constraint(:user_id, name: "mentor_mentor_id_fkey")
  end
end
