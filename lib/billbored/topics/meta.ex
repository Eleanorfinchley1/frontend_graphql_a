defmodule BillBored.Topics.Topic.Meta do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key false
  embedded_schema do
    field :university_name, :string
    field :topics, {:array, :string}
  end

  @doc false
  def changeset(meta, attrs \\ %{}) do
    meta
    |> cast(attrs, [:university_name, :topics])
    |> validate_required([:university_name, :topics])
    |> validate_length(:topics, is: 10)
  end
end

