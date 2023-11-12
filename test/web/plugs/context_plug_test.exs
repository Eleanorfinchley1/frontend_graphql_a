defmodule Web.ContextPlugTest do
  use Web.ConnCase, async: true
  alias BillBored.User

  test "with valid token", %{conn: conn} do
    %User.AuthToken{user: %User{id: user_id}, key: token} = insert(:auth_token)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Context.call([])

    refute conn.halted
    assert conn.assigns.user_id == user_id
  end

  test "with invalid token", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer asdkfjhgadsf")
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Context.call([])

    assert conn.halted
    assert conn.status == 403
  end

  test "without token", %{conn: conn} do
    conn =
      conn
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Context.call([])

    refute conn.halted
    assert conn.assigns.user_id == nil
  end
end
