defmodule Web.UniversityControllerTest do
  use Web.ConnCase

  @univerity_attr %{"name" => "abcd", "country" => "Canada", "allowed" => true, "avatar" => "media/images/123.png", "avatar_thumbnail" => "media/images/123.png"}

  describe "university controller" do
    test "create a university", %{conn: conn} do
      response =
        conn
        |> post(Routes.university_path(conn, :create, @univerity_attr))
        |> json_response(200)

      assert response["data"]["name"] == "abcd"
      assert response["data"]["country"] == "Canada"
      assert response["data"]["allowed"] == true
    end
  end
end
