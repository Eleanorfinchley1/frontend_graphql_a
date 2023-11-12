defmodule BillBored.Torch.InterestCategoryDecorator do
  @moduledoc false

  import Ecto.Changeset
  use Ecto.Schema

  alias BillBored.InterestCategory

  embedded_schema do
    field :name, :string
    field :icon, :string
    field :interests_text, :string
    field :interests, {:array, :map}, default: []
  end

  def changeset(%InterestCategory{} = interest_category, attrs \\ %{}) do
    build_decorator(interest_category)
    |> cast(attrs, [:name, :icon, :interests_text])
    |> validate_required([:name, :interests_text])
    |> cast_interests()
  end

  def update_changeset(interest_category, attrs \\ %{}) do
    Map.put(changeset(interest_category, attrs), :action, :update)
  end

  defp build_decorator(%InterestCategory{} = interest_category) do
    interests_text = if Ecto.assoc_loaded?(interest_category.interests) do
      interest_category.interests |> Enum.map_join("\n", fn %{hashtag: hashtag, icon: icon} -> "#{hashtag};#{icon}" end)
    else
      ""
    end

    %__MODULE__{
      id: interest_category.id,
      name: interest_category.name,
      icon: interest_category.icon,
      interests_text: interests_text
    }
    |> Map.put(:__meta__, interest_category.__meta__)
  end

  defp cast_interests(changeset) do
    case get_field(changeset, :interests_text) do
      nil ->
        changeset

      text ->
        put_change(changeset, :interests, parse_interests(text))
    end
  end

  defp parse_interests(interests_text) do
    interests_text
    |> String.split("\n")
    |> Enum.map(fn i -> i |> String.trim() |> String.downcase() end)
    |> Enum.map(fn i ->
      case String.split(i, ";") do
        [name] ->
          %BillBored.Interest{hashtag: BillBored.Interest.normalize(name)}

        [name, icon] ->
          %BillBored.Interest{hashtag: BillBored.Interest.normalize(name), icon: BillBored.Interest.normalize_icon(icon)}
      end
    end)
  end
end
