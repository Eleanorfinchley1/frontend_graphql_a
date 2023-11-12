defmodule BillBored.Topics.Topic do
  use Ecto.Schema
  import Ecto.Changeset
  alias BillBored.Topics.Topic.Meta

  schema "topics" do
    embeds_many(:meta, Meta, on_replace: :delete)
  end

  @doc false
  def changeset(topics, meta \\ []) do
    topics
    |> change()
    |> put_embed(:meta, meta)
    |> validate_length(:meta, min: 2)
  end
end

