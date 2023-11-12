defmodule BillBored.KVEntries.CovidInfo do
  use BillBored, :schema
  import Ecto.Changeset

  defmodule Value do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :enabled, :boolean
      field :info, :string, default: ""
    end

    @doc false
    def changeset(value, attrs \\ %{}) do
      value
      |> cast(attrs, [:enabled, :info])
    end
  end

  defimpl Jason.Encoder, for: __MODULE__.Value do
    def encode(value, opts) do
      Jason.Encode.map(Map.take(value, [:enabled, :info]), opts)
    end
  end

  @primary_key false
  schema "kv_entries" do
    field(:key, :string, primary_key: true)
    embeds_one :value, __MODULE__.Value, on_replace: :update

    timestamps(inserted_at: false, updated_at: :updated_at)
  end

  @doc false
  def changeset(covid_info, attrs \\ %{}) do
    covid_info
    |> cast(Map.put(attrs, "key", "covid_info"), [:key])
    |> cast_embed(:value)
  end
end
