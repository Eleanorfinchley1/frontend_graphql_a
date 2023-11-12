defmodule BillBored.User.AuthTokensTest do
  use BillBored.DataCase, async: true

  alias BillBored.User

  setup do
    %{auth_token: insert(:auth_token)}
  end

  test "get by token key", %{auth_token: %User.AuthToken{key: token_key, user_id: user_id}} do
    %User.AuthToken{} = fetched_auth_token = User.AuthTokens.get_by_key(token_key)

    assert fetched_auth_token.user_id == user_id
    assert fetched_auth_token.key == token_key
  end
end
