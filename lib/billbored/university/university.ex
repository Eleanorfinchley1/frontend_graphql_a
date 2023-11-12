defmodule BillBored.University do
  @moduledoc "Schema for university table"
  use BillBored, :schema

  @type t :: %__MODULE__{
          name: String.t(),
          country: String.t(),
          allowed: boolean(),
          avatar: String.t(),
          avatar_thumbnail: String.t(),
          icon: String.t()
        }

  @derive {Jason.Encoder,
  only: [
    :name,
    :country,
    :allowed,
    :avatar,
    :avatar_thumbnail,
    :icon
  ]}

  schema "university" do
    field :name, :string
    field :country, :string
    field :allowed, :boolean
    field :avatar, :string
    field :avatar_thumbnail, :string
    field :icon, :string

    # Virtual fields
    field(:semester_points, :integer, virtual: true)
    field(:monthly_points, :integer, virtual: true)
    field(:weekly_points, :integer, virtual: true)
    field(:daily_points, :integer, virtual: true)
    field(:total_points, :integer, virtual: true)
  end


  @doc "Changeset for university struct"
  def changeset(university, attrs \\ %{}) do
    university
    |> cast(attrs, __MODULE__.__schema__(:fields))
    |> validate_required([:name, :country, :allowed, :avatar, :avatar_thumbnail])
    |> unique_constraint([:name, :country])
  end
end
