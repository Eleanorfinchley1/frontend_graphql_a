defmodule Web.DeviceControllerTest do
  use Web.ConnCase, async: false

  import BillBored.Factory

  setup do
    %{
      user: insert(:user)
    }
  end

  describe "create" do
    test "creates token", %{conn: conn, user: %{id: user_id} = user} do
      assert %{
               "id" => _,
               "token" => "01234-567",
               "platform" => "ios",
               "user" => %{
                 "id" => ^user_id
               }
             } =
               conn
               |> authenticate(user)
               |> post(Routes.device_path(conn, :create), %{
                 "platform" => "ios",
                 "token" => "01234-567"
               })
               |> json_response(200)

      assert [
               %{
                 token: "01234-567",
                 platform: "ios",
                 user_id: ^user_id
               }
             ] = Repo.preload(user, [:devices]).devices
    end
  end

  describe "when current user is banned" do
    setup do
      %{
        user: insert(:user, banned?: true)
      }
    end

    test "can't create device", %{conn: conn, user: user} do
      assert %{"success" => false, "error" => "banned"} =
               conn
               |> authenticate(user)
               |> post(Routes.device_path(conn, :create), %{
                 "platform" => "ios",
                 "token" => "01234-567"
               })
               |> json_response(403)

      assert [] == Repo.preload(user, [:devices]).devices
    end
  end

  describe "when current user is restricted" do
    setup do
      %{
        user:
          insert(:user,
            flags: %{"access" => "restricted", "restriction_reason" => "a valid reason"}
          )
      }
    end

    test "still can create device", %{conn: conn, user: %{id: user_id} = user} do
      assert %{
               "id" => _,
               "token" => "01234-567",
               "platform" => "ios",
               "user" => %{
                 "id" => ^user_id
               }
             } =
               conn
               |> authenticate(user)
               |> post(Routes.device_path(conn, :create), %{
                 "platform" => "ios",
                 "token" => "01234-567"
               })
               |> json_response(200)
    end
  end
end
