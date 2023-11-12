defmodule Repo do
  use Ecto.Repo, otp_app: :billbored, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 10

  if Mix.env() in [:dev, :test, :bench] do
    @doc "Truncates the table, currently used for benchmarks only."
    def truncate(schema) do
      table_name = schema.__schema__(:source)

      case query("TRUNCATE #{table_name} CASCADE", []) do
        {:ok, _} -> :ok
        other -> other
      end
    end
  end

  def quote_value(value) when is_binary(value) do
    [?', :binary.replace(value, "'", "''", [:global]), ?']
  end
end
