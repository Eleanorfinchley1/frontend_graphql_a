defmodule BillBored.Clickhouse do
  def initialize() do
    conn = Pillar.Connection.new(Application.fetch_env!(:billbored, Pillar)[:url])
    Application.put_env(:billbored, Pillar, %{conn: conn})
  end

  def conn(), do: Application.fetch_env!(:billbored, Pillar)[:conn]
end