defmodule Signer do
  @moduledoc """
  For https://cloud.google.com/storage/docs/access-control/signed-urls
  and https://cloud.google.com/storage/docs/access-control/create-signed-urls-program
  """

  @base_url "https://storage.googleapis.com"

  @doc """
  Creates signed urls for downloading:
      
      iex> expires_at = :os.system_time(:seconds) + 60 * 60 # after one hour in seconds
      iex> path = "/some-bucket/some-file"
      iex> create_signed_url("GET", expires_at, path)

  and uploading:
      
      iex> content_type = "audio/mp4"
      iex> path = "/some-bucket/some-file.m4a"
      iex> create_signed_url("PUT", content_type, expires_at, path)

  """
  def create_signed_url(method, content_type \\ "", expires_at, path) do
    # to_sign = [
    #   http_verb,
    #   ?\n,
    #   content_md5,
    #   ?\n,
    #   content_type,
    #   ?\n,
    #   expiration,
    #   ?\n,
    #   canonicalized_extension_headers,
    #   ?\n,
    #   canonicalized_resource
    # ]

    data = [
      method,
      ?\n,
      # md5
      ?\n,
      content_type,
      ?\n,
      :erlang.integer_to_binary(expires_at),
      ?\n,
      path
    ]

    client_email = Signer.Config.get!(:client_email)
    key = Signer.Config.get!(:private_key_record)

    # base64 encoded signature may contain characters not legal in urls (specifically + and /)
    # these values must be replaced by safe encodings (%2B and %2F, respectively)

    signature =
      data
      |> IO.iodata_to_binary()
      |> :public_key.sign(:sha256, key)
      |> Base.encode64()
      |> escape()

    @base_url <>
      path <>
      "?GoogleAccessId=#{client_email}" <> "&Expires=#{expires_at}" <> "&Signature=#{signature}"
  end

  @spec escape(binary) :: binary
  defp escape("+" <> rest), do: "%2B" <> escape(rest)
  defp escape("/" <> rest), do: "%2F" <> escape(rest)
  defp escape("=" <> rest), do: "%3D" <> escape(rest)
  defp escape(<<char, rest::bytes>>), do: <<char, escape(rest)::bytes>>
  defp escape(<<>>), do: <<>>
end
