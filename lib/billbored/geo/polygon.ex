defmodule BillBored.Geo.Polygon do
  @moduledoc """
  Acts as an intermediate type between client supplied geographical polygons
  of the form `[(lat, long)]` and postgis `[POINT(long, lat)]`.

  Mostly exists to avoid confusion. Only used in queries, not actually stored to DB.
  """

  @enforce_keys [:coords]
  defstruct coords: []

  use Ecto.Type
  alias Geo.PostGIS.Geometry

  @impl true
  defdelegate type, to: Geometry

  @impl true
  def load(_any), do: :error

  @impl true
  def dump(%__MODULE__{} = polygon), do: {:ok, polygon}
  def dump(_other), do: :error

  @impl true
  def cast(_any), do: :error
end
