defmodule SignerTest do
  use ExUnit.Case, async: true

  test "create_signed_url/3" do
    # after one hour
    expires_at = :os.system_time(:seconds) + 60 * 60
    assert Signer.create_signed_url("GET", expires_at, "test/test")
  end
end
