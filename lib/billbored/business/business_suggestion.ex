defmodule BillBored.BusinessSuggestion do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias BillBored.User

  @type t :: %__MODULE__{}
  @timestamps_opts [type: :utc_datetime_usec]

  schema "business_suggestions" do
    field(:suggestion, :string)
    timestamps()

    belongs_to(:business, User)
  end

  def changeset(suggestion, attrs) do
    suggestion
    |> cast(attrs, [:suggestion])
    |> validate_length(:suggestion, min: 10)
  end
end
