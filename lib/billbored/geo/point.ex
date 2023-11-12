defmodule BillBored.Geo.Point do
  @moduledoc """
  Acts as an intermediate type between client supplied geographical points
  of the form `(lat, long)` and postgis `(long, lat)`.

  Mostly exists to avoid confusion.
  """

  @enforce_keys [:lat, :long]
  defstruct [:lat, :long]

  use Ecto.Type
  alias Geo.PostGIS.Geometry

  @impl true
  defdelegate type, to: Geometry

  @impl true
  def load(%__MODULE__{} = point), do: {:ok, point}

  def load(geom) do
    case Geometry.load(geom) do
      # we don't expect anything other than a point
      {:ok, %Geo.Point{coordinates: {long, lat}}} ->
        {:ok, %__MODULE__{lat: lat, long: long}}

      :error = error ->
        error
    end
  end

  @impl true
  def dump(%__MODULE__{} = point), do: {:ok, point}
  def dump(_other), do: :error

  @impl true
  def cast(%__MODULE__{} = point), do: {:ok, point}

  def cast([lat, long]) do
    {:ok, %__MODULE__{lat: lat, long: long}}
  end

  def cast(geom) do
    case Geometry.cast(geom) do
      # we don't expect anything other than a point
      # the client erroneously sends the latitude first
      {:ok, %Geo.Point{coordinates: {lat, long}}} ->
        {:ok, %__MODULE__{lat: lat, long: long}}

      :error = error ->
        error
    end
  end
end
