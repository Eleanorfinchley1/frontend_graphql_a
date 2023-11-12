defmodule Web.NginxControllerTest do
  use Web.ConnCase, async: true
  alias BillBored.User

  describe "publish callback" do
    setup [:create_streamer, :create_livestream]

    @tag :skip
    test "with valid params", %{conn: conn, token: token, livestream: livestream} do
      resp =
        post(conn, Routes.nginx_path(conn, :publish), %{
          "name" => livestream.id,
          "token" => token
        })

      assert resp.status == 200
    end

    test "with empty token", %{conn: conn, livestream: livestream} do
      resp =
        post(conn, Routes.nginx_path(conn, :publish), %{
          "name" => livestream.id,
          "token" => ""
        })

      assert resp.status == 403
    end

    test "with token for other livestream owner", %{
      conn: conn,
      token: token
    } do
      another_livestream = insert(:livestream, location: %BillBored.Geo.Point{lat: 30, long: 31})

      resp =
        post(conn, Routes.nginx_path(conn, :publish), %{
          "name" => another_livestream.id,
          "token" => token
        })

      assert resp.status == 403
    end
  end

  describe "publish_done callback" do
    setup [:create_streamer, :create_livestream]

    @tag :skip
    test "with valid params", %{conn: conn, livestream: livestream} do
      resp =
        post(conn, Routes.nginx_path(conn, :publish_done), %{
          "name" => livestream.id,
          "token" => ""
        })

      assert resp.status == 200
    end
  end

  defp create_streamer(_context) do
    %User.AuthToken{user: %User{} = user, key: token_key} = insert(:auth_token)
    {:ok, %{token: token_key, user: user}}
  end

  defp create_livestream(%{user: %User{} = owner}) do
    {:ok,
     %{
       livestream:
         insert(
           :livestream,
           owner: owner,
           location: %BillBored.Geo.Point{lat: 30, long: 31}
         )
     }}
  end
end
