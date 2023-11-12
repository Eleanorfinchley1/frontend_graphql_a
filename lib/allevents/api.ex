defmodule Allevents.API do
  @moduledoc false
  use HTTPoison.Base

  @base_url "https://api.allevents.in"
  @timeout 5_000
  @recv_timeout 5_000

  @sub_key_header "Ocp-Apim-Subscription-Key"

  def get_events_by_geo(params) do
    query = URI.encode_query(params)
    headers = [{@sub_key_header, subscription_key()}]
    path = "#{@base_url}/events/geo/"

    with {:ok, %HTTPoison.Response{} = response} <-
           post("#{path}?#{query}", "", headers,
             timeout: @timeout,
             recv_timeout: @recv_timeout
           ) do
      with {:ok, next_page_params} <- extract_next_page_params(path, params, response),
           {:ok, events} <- extract_events(response) do
        {:ok, events, %{next_page_params: next_page_params}}
      end
    end
  end

  defp extract_events(%HTTPoison.Response{body: json_body}) do
    case json_body do
      %{"error" => 0, "data" => events} -> {:ok, events}
      _ -> {:error, :invalid_response}
    end
  end

  defp extract_next_page_params(_path, params, %HTTPoison.Response{body: json_body}) do
    case json_body do
      %{error: :invalid_json} ->
        {:ok, nil}

      %{"request" => %{"rows" => 0}} ->
        {:ok, nil}

      %{"request" => %{"data" => []}} ->
        {:ok, nil}

      %{"request" => %{"page" => page}} ->
        {:ok, Map.merge(params, %{"page" => page + 1})}

      _ ->
        {:ok, Map.merge(params, %{"page" => 1})}
    end
  end

  defp subscription_key() do
    config()
    |> Keyword.fetch!(:subscription_key)
    |> maybe_system_var()
    |> to_string()
  end

  defp config, do: Application.fetch_env!(:billbored, __MODULE__)

  defp maybe_system_var({:system, var}), do: System.get_env(var)
  defp maybe_system_var(value), do: value

  @impl true
  def process_response_body(body) do
    case Jason.decode(body) do
      {:ok, body} ->
        body

      {:error, _reason} ->
        %{error: :invalid_json}
    end
  end
end
