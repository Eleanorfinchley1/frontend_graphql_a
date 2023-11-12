defmodule BillBored.Agora.Tokens do
  import BillBored.ServiceRegistry, only: [service: 1]

  def generate_token(channel, uid, ttl, role) do
    config = Application.fetch_env!(:billbored, __MODULE__)

    args = [
      "-appID",
      config[:app_id],
      "-appCertificate",
      config[:app_certificate],
      "-channelName",
      channel,
      "-uid",
      to_string(uid),
      "-ttl",
      to_string(ttl),
      "-role",
      to_string(role)
    ]

    case System.cmd(config[:generator_path], args) do
      {result, 0} -> {:ok, result}
      {error, _} -> {:error, error}
    end
  end

  def fetch_user_token(%BillBored.User{id: user_id}, channel, ttl, role, force_refresh \\ false) do
    key = "agora_tokens:#{channel}:#{user_id}:#{role}"

    result =
      if force_refresh || key_ttl(key) < 30 do
        generate_token(channel, 0, ttl, role)
      else
        service(BillBored.Redix).command(["GET", key])
      end

    with {:ok, token} <- result do
      {:ok, "OK"} = service(BillBored.Redix).command(["SETEX", key, to_string(ttl), token])
      {:ok, token}
    end
  end

  defp key_ttl(key) do
    {:ok, key_ttl} = service(BillBored.Redix).command(["TTL", key])
    key_ttl
  end
end
