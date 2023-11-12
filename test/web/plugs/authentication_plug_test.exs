defmodule Web.AuthenticationPlugTest do
  use Web.ConnCase, async: true

  test "with user_id set and user_registration_status is allowed", %{conn: conn} do
    conn =
      conn
      |> assign(:user_id, 1)
      |> assign(:user_registration_status, :complete)
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Authentication.call([:complete])

    refute conn.halted
  end

  test "with user_id set and user_registration_status is not allowed", %{conn: conn} do
    conn =
      conn
      |> assign(:user_id, 1)
      |> assign(:user_registration_status, :complete)
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Authentication.call([])

    assert conn.halted
    assert conn.status == 401
    assert {"www-authenticate", "Bearer"} in conn.resp_headers
  end

  test "without user_id", %{conn: conn} do
    conn =
      conn
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Authentication.call([])

    assert conn.halted
    assert conn.status == 401
    assert {"www-authenticate", "Bearer"} in conn.resp_headers
  end

  test "without user_registration_status", %{conn: conn} do
    conn =
      conn
      |> assign(:user_id, 1)
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Authentication.call([])

    assert conn.halted
    assert conn.status == 401
    assert {"www-authenticate", "Bearer"} in conn.resp_headers
  end
end
