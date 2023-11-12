defmodule Web.LivestreamControllerTest do
  use Web.ConnCase, async: true

  describe "create" do
    setup [:create_streamer]

    test "with valid params", %{conn: conn, token: token} do
      livestream_params = %{
        "title" => "some livestream",
        "location" => %{
          "coordinates" => [40.5, -50.0],
          "type" => "Point"
        }
      }

      assert %{
               "title" => "some livestream"
             } =
               conn
               |> authenticate(token)
               |> post(Routes.livestream_path(conn, :create), livestream_params)
               |> json_response(200)
    end

    test "with empty params", %{conn: conn, token: token} do
      assert %{
               "reason" => %{"location" => ["can't be blank"], "title" => ["can't be blank"]},
               "success" => false
             } ==
               conn
               |> authenticate(token)
               |> post(Routes.livestream_path(conn, :create), %{})
               |> json_response(422)
    end
  end

  defp create_streamer(_context) do
    token = insert(:auth_token)
    {:ok, %{token: token, user: token.user}}
  end
end
