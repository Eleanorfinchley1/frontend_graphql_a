defmodule Meetup.API do
  @moduledoc false
  use HTTPoison.Base

  @base_url "https://api.meetup.com"
  @timeout 5_000
  @recv_timeout 5_000

  @spec find_upcoming_events(%{required(binary()) => any()}) ::
          {:ok, list(map()), map()} | {:error, atom()}
  def find_upcoming_events(params) do
    with {:ok, access_token} <- Meetup.API.Auth.get_access_token() do
      do_find_upcoming_events(access_token, params)
    end
  end

  defp do_find_upcoming_events(access_token, params) do
    query = URI.encode_query(params)
    headers = [{"authorization", "Bearer #{access_token}"}]

    path = "#{@base_url}/find/upcoming_events"

    with {:ok, %HTTPoison.Response{} = response} <-
           get("#{path}?#{query}", headers,
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
      %{"events" => events} -> {:ok, events}
      _ -> {:error, :invalid_response}
    end
  end

  defp extract_next_page_params(path, _params, %HTTPoison.Response{headers: headers}) do
    regex = ~r/<#{Regex.escape(path)}\?(.*?)>; rel="(.*?)"/

    next_page_params =
      Enum.reduce_while(headers, nil, fn
        {"Link", header_value}, acc ->
          case Regex.run(regex, header_value) do
            [_, query, "next"] -> {:halt, URI.decode_query(query)}
            _ -> {:cont, acc}
          end

        _, acc ->
          {:cont, acc}
      end)

    {:ok, next_page_params}
  end

  @impl true
  def process_response_body(body) do
    case Jason.decode(body) do
      {:ok, body} ->
        body

      {:error, reason} ->
        raise "Failed to decode Meetup response: #{inspect(reason)}\n#{inspect(body)}"
    end
  end
end
