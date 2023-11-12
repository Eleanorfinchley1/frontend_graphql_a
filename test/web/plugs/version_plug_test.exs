defmodule Web.Plugs.VersionTest do
  use Web.ConnCase, async: true

  test "x-version header with commit sha gets added to an api request", %{conn: conn} do
    assert [commit_sha]=
      conn
      |> bypass_through(Web.Router, [:api])
      |> Web.Plugs.Version.call([])
      |> get_resp_header("x-version")

    assert String.length(commit_sha) == 12
  end
end
