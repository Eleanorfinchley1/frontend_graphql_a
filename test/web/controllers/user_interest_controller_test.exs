defmodule Web.UserInterestControllerTest do
  use Web.ConnCase, async: true

  setup %{conn: conn} do
    %{user: user, key: token} = insert(:auth_token)
    {:ok, conn: put_req_header(conn, "authorization", "Bearer #{token}"), user: user}
  end

  test "create, list, delete", %{conn: conn} do
    i1 = insert(:interest, hashtag: "interest-1")
    i2 = insert(:interest, hashtag: "interest-2")

    assert [] ==
             conn
             |> get(Routes.user_interest_path(conn, :list))
             |> json_response(200)

    assert "" ==
             conn
             |> post(Routes.user_interest_path(conn, :create), %{"interest" => i1.id})
             |> response(204)

    assert [
             %{
               "disabled?" => false,
               "hashtag" => "interest-1",
               "id" => _,
               "inserted_at" => _
             }
           ] =
             conn
             |> get(Routes.user_interest_path(conn, :list))
             |> json_response(200)

    assert "" ==
             conn
             |> post(Routes.user_interest_path(conn, :create), %{"interest" => i2.id})
             |> response(204)

    assert [
             %{
               "disabled?" => false,
               "hashtag" => "interest-1"
             },
             %{
               "disabled?" => false,
               "hashtag" => "interest-2"
             }
           ] =
             conn
             |> get(Routes.user_interest_path(conn, :list))
             |> json_response(200)

    assert "" ==
             conn
             |> delete(Routes.user_interest_path(conn, :delete, i2.id))
             |> response(204)

    assert [
             %{
               "disabled?" => false,
               "hashtag" => "interest-1"
             }
           ] =
             conn
             |> get(Routes.user_interest_path(conn, :list))
             |> json_response(200)
  end
end
