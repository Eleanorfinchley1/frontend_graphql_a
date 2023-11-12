defmodule BillBored.Hashtag do
  @moduledoc "schema for custom_hashtags table"

  use Ecto.Schema

  @type t :: %__MODULE__{}

  schema "custom_hashtags" do
    field(:value, :string)
    timestamps(type: :naive_datetime_usec)
  end
end
