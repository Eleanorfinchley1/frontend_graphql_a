defmodule BillBored.Agora.API do
  @moduledoc false
  use HTTPoison.Base

  require Logger

  @base_url "https://api.agora.io"
  @timeout 5_000
  @recv_timeout 5_000

  def config do
    Application.fetch_env!(:billbored, __MODULE__)
  end

  def basic_auth(), do: config()[:basic_auth]
  def app_id(), do: config()[:app_id]
  def s3_config(), do: config()[:s3_config]

  def public_url(filename) do
    "#{s3_config()[:public_prefix]}/#{filename}"
  end

  def acquire_recording(channel_name, uid) do
    params = %{
      "cname" => channel_name,
      "uid" => to_string(uid),
      "clientRequest" => %{
        "resourceExpiredHour" => 24
      }
    }

    headers = [
      {"authorization", "Basic #{basic_auth()}"},
      {"content-type", "application/json;charset=utf-8"}
    ]

    path = "#{@base_url}/v1/apps/#{app_id()}/cloud_recording/acquire"
    body = Jason.encode!(params)

    with {:ok, %HTTPoison.Response{} = response} <- make_request(:post, "#{path}", body, headers),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      error ->
        handle_error(error)
    end
  end

  def start_recording(channel_name, uid, resource_id, s3_config) do
    {:ok, token} = BillBored.Agora.Tokens.generate_token(channel_name, uid, 10800, "subscriber")

    params = %{
      "cname" => channel_name,
      "uid" => to_string(uid),
      "clientRequest" => %{
        "token" => token,
        "recordingConfig" => %{
          "channelType" => 1,
          "streamTypes" => 0,
          "maxIdleTime" => 10800
        },
        "recordingFileConfig" => %{
          "avFileType" => ["hls", "mp4"]
        },
        "storageConfig" => %{
          "vendor" => 1,
          "region" => 1,
          "bucket" => s3_config[:bucket],
          "accessKey" => s3_config[:access_key],
          "secretKey" => s3_config[:secret_key]
        }
      }
    }

    headers = [
      {"authorization", "Basic #{basic_auth()}"},
      {"content-type", "application/json;charset=utf-8"}
    ]

    path = "#{@base_url}/v1/apps/#{app_id()}/cloud_recording/resourceid/#{resource_id}/mode/mix/start"
    body = Jason.encode!(params)

    with {:ok, %HTTPoison.Response{} = response} <- make_request(:post, "#{path}", body, headers),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      error ->
        handle_error(error)
    end
  end

  def recording_status(sid, resource_id) do
    headers = [
      {"authorization", "Basic #{basic_auth()}"},
      {"content-type", "application/json;charset=utf-8"}
    ]

    path = "#{@base_url}/v1/apps/#{app_id()}/cloud_recording/resourceid/#{resource_id}/sid/#{sid}/mode/mix/query"

    with {:ok, %HTTPoison.Response{} = response} <- make_request(:get, "#{path}", nil, headers),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      error ->
        handle_error(error)
    end
  end

  def stop_recording(sid, resource_id, channel_name, uid) do
    params = %{
      "cname" => channel_name,
      "uid" => to_string(uid),
      "clientRequest" => %{}
    }

    headers = [
      {"authorization", "Basic #{basic_auth()}"},
      {"content-type", "application/json;charset=utf-8"}
    ]

    path = "#{@base_url}/v1/apps/#{app_id()}/cloud_recording/resourceid/#{resource_id}/sid/#{sid}/mode/mix/stop"
    body = Jason.encode!(params)

    with {:ok, %HTTPoison.Response{} = response} <- make_request(:post, "#{path}", body, headers),
         {:ok, response} <- parse_response(response) do
      {:ok, response}
    else
      error ->
        handle_error(error)
    end
  end

  def remove_stream_recordings(sid) do
    try do
      files_to_delete =
        ExAws.S3.list_objects(s3_config()[:bucket], prefix: sid)
        |> ExAws.stream!()
        |> Enum.map(fn %{key: key} -> key end)
        |> Enum.filter(fn filename -> Path.extname(filename) in [".ts", ".mp4", ".m3u8"] end)

      Logger.debug("Removing #{Enum.count(files_to_delete)} stream recording files from S3 for sid #{inspect(sid)}")

      files_to_delete
      |> Enum.chunk_every(1000)
      |> Enum.map(fn files ->
        result = ExAws.S3.delete_multiple_objects(s3_config()[:bucket], files) |> ExAws.request!()
        Logger.debug("[S3] Remove #{Enum.count(files)} objects from #{inspect(s3_config()[:bucket])}: #{inspect(result)}")
      end)
    rescue
      error ->
        Logger.error("[S3] Failed to remove stream recordings for sid #{inspect(sid)}: #{inspect(error)}")
        {:error, :s3_error}
    end

    :ok
  end

  defp make_request(method, path, body, headers) do
    Logger.debug("AGORA REQUEST: #{path} body=#{body}")

    result = case method do
      :post -> post("#{path}", body, headers, timeout: @timeout, recv_timeout: @recv_timeout)
      :get -> get("#{path}", headers, timeout: @timeout, recv_timeout: @recv_timeout)
    end

    case result do
      {:ok, %HTTPoison.Response{body: body}} when is_binary(body) ->
        Logger.debug("AGORA RESPONSE OK: #{body}")

      {:error, %HTTPoison.Response{body: body}} when is_binary(body) ->
        Logger.debug("AGORA RESPONSE ERROR: #{body}")

      {status, response} ->
        Logger.debug("AGORA RESPONSE UNKNOWN: #{inspect(status)} #{inspect(response)}")
    end

    result
  end

  defp parse_response(%HTTPoison.Response{} = response) do
    Jason.decode(response.body)
  end

  defp handle_error({:error, %HTTPoison.Response{} = response} = error) do
    case parse_response(response) do
      {:ok, %{"code" => 432}} ->
        {:error, :invalid_parameters}

      {:ok, %{"code" => 433}} ->
        {:error, :resource_expired}

      {:ok, %{"code" => 435}} ->
        {:error, :nothing_recorded}

      _ -> error
    end
  end
  defp handle_error(error), do: error
end
