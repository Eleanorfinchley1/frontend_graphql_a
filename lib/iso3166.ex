defmodule Iso3166 do
  require Logger

  @ets_name __MODULE__

  def initialize do
    :ets.new(@ets_name, [:set, :public, :named_table, {:read_concurrency, true}])

    try do
      Path.join(:code.priv_dir(:billbored), "iso3166.json")
      |> File.read!()
      |> Jason.decode!()
      |> Enum.each(fn %{"alpha-3" => alpha3, "name" => country} ->
        :ets.insert(@ets_name, {alpha3, country})
      end)
    catch
      e ->
        Logger.error("Failed to load ISO-3166 country names: #{inspect(e)}")
    end
  end

  def get(alpha3) do
    case :ets.lookup(@ets_name, alpha3) do
      [{^alpha3, value}] -> value
      _ -> nil
    end
  end
end
