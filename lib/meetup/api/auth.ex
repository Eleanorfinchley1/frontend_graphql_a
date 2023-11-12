defmodule Meetup.API.Auth do
  @moduledoc false
  use HTTPoison.Base

  @base_url "https://secure.meetup.com/oauth2"
  @timeout 5_000
  @recv_timeout 5_000
  @ets_name __MODULE__

  def initialize do
    :ets.new(@ets_name, [:set, :public, :named_table, {:read_concurrency, true}])
  end

  def get_authorize do
    query =
      URI.encode_query(%{
        "redirect_uri" => redirect_uri(),
        "client_id" => api_key(),
        "response_type" => "anonymous_code"
      })

    # required to avoid redirect and to receive code from Meetup
    headers = [
      {"accept", "application/json"}
    ]

    with {:ok, %HTTPoison.Response{body: json_body}} <-
           get("#{@base_url}/authorize?#{query}", headers,
             timeout: @timeout,
             recv_timeout: @recv_timeout
           ) do
      case json_body do
        %{"code" => _code} = valid_response -> {:ok, valid_response}
        _ -> {:error, :invalid_response}
      end
    end
  end

  def get_access(code) do
    query =
      URI.encode_query(%{
        "redirect_uri" => redirect_uri(),
        "client_id" => api_key(),
        "client_secret" => api_secret(),
        "grant_type" => "anonymous_code",
        "code" => code
      })

    with {:ok, %HTTPoison.Response{body: json_body}} <-
           post("#{@base_url}/access?#{query}", [], timeout: @timeout, recv_timeout: @recv_timeout) do
      case json_body do
        %{"access_token" => _access_token} = valid_response -> {:ok, valid_response}
        _ -> {:error, :invalid_response}
      end
    end
  end

  def get_access_token do
    case ets_get(:auth_info) do
      {:ok, %{"access_token" => access_token}} ->
        {:ok, access_token}

      nil ->
        with {:ok, %{"code" => code}} <- get_authorize(),
             {:ok, %{"access_token" => access_token} = auth_info} <- get_access(code) do
          ets_put(:auth_info, auth_info)
          {:ok, access_token}
        end
    end
  end

  defp ets_get(key) do
    case :ets.lookup(@ets_name, key) do
      [{^key, value}] -> {:ok, value}
      _ -> nil
    end
  end

  defp ets_put(key, value) do
    :ets.insert(@ets_name, {key, value})
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

  defp redirect_uri do
    config() |> Keyword.fetch!(:redirect_uri)
  end

  defp api_key do
    config() |> Keyword.fetch!(:consumer_key)
  end

  defp api_secret do
    config()
    |> Keyword.fetch!(:consumer_secret)
    |> maybe_system_var()
    |> to_string()
  end

  defp config, do: Application.fetch_env!(:billbored, Meetup.API)

  defp maybe_system_var({:system, var}), do: System.get_env(var)
  defp maybe_system_var(value), do: value
end
