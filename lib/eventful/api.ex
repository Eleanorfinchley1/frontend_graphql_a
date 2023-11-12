defmodule Eventful.API do
  @moduledoc false
  use HTTPoison.Base

  @base_url "https://api.eventful.com/json"

  defp api_key do
    get_in(Application.get_env(:billbored, __MODULE__), [:api_key]) ||
      raise("missing #{__MODULE__} api key")
  end

  @impl true
  def process_request_url(path) do
    %URI{query: query} = uri = URI.parse(@base_url <> path)
    query_args = :binary.split(query, "&", [:global, :trim])
    query = Enum.join(["app_key=#{api_key()}" | query_args], "&")
    URI.to_string(%URI{uri | query: query})
  end

  @impl true
  def process_response_body(body) do
    case Jason.decode(body) do
      {:ok, body} ->
        body

      {:error, _reason} ->
        raise "Failed to decode Eventful response:\n\n#{inspect(body)}"
    end
  end
end
