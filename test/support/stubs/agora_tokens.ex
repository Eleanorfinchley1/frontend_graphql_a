defmodule BillBored.Stubs.AgoraTokens do
  def fetch_user_token(_user, _channel, _ttl, _role, _force_refresh \\ false) do
    {:ok, "test-token"}
  end
end
