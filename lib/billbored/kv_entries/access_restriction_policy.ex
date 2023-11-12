defmodule BillBored.KVEntries.AccessRestrictionPolicy do
  use BillBored, :schema
  import Ecto.Changeset
  import Ecto.Query

  defmodule Value do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field :enabled, :boolean
    end

    @doc false
    def changeset(value, attrs \\ %{}) do
      value
      |> cast(attrs, [:enabled])
    end
  end

  defimpl Jason.Encoder, for: __MODULE__.Value do
    def encode(value, opts) do
      Jason.Encode.map(Map.take(value, [:enabled]), opts)
    end
  end

  @primary_key false
  schema "kv_entries" do
    field(:key, :string, primary_key: true)
    embeds_one :value, __MODULE__.Value, on_replace: :update

    timestamps(inserted_at: false, updated_at: :updated_at)
  end

  @doc false
  def changeset(arp, attrs \\ %{}) do
    arp
    |> cast(Map.put(attrs, "key", "access_restriction_policy"), [:key])
    |> cast_embed(:value)
  end

  def get() do
    from(e in __MODULE__, where: e.key == "access_restriction_policy")
    |> Repo.one()
  end
end
