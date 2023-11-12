defmodule BillBored.Poll do
  use BillBored, :schema
  alias BillBored.{Post, PollItem}

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "polls" do
    field(:question, :string)

    belongs_to(:post, Post, foreign_key: :post_id)
    has_many(:items, PollItem, foreign_key: :poll_id, on_replace: :delete)

    timestamps(inserted_at: :inserted_at, updated_at: :updated_at)
  end

  defp wrap_items(%{"items" => items} = params) do
    items =
      for item <- items do
        if is_binary(item) do
          %{"title" => item}
        end || item
      end

    %{params | "items" => items}
  end

  defp wrap_items(params), do: params

  defp trim_items(%{"items" => items} = params) do
    items =
      for item <- items do
        title = item["title"]

        if title do
          Map.put(item, "title", String.trim(title))
        end || item
      end

    Map.put(params, "items", items)
  end

  defp trim_items(params), do: params

  defp uniq_items(%{"items" => items} = params) do
    Map.put(params, "items", Enum.uniq(items))
  end

  defp uniq_items(params), do: params

  def changeset(poll, params \\ %{}) do
    params =
      params
      |> wrap_items()
      |> trim_items()
      |> uniq_items()

    poll
    |> cast(params, [:question, :post_id])
    |> cast_assoc(:items, with: &PollItem.changeset/2)
    |> validate_required([:question])
    |> foreign_key_constraint(:post_id)
    |> validate_length(:question, min: 5, max: 250)
  end
end
