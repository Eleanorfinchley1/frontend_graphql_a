defmodule Web.AccountControllerTest do
  use Web.ConnCase, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import BillBored.ServiceRegistry, only: [replace: 2]

  alias BillBored.Users

  setup_all do
    HTTPoison.start()
  end

  @valid_params %{
    "area" => "East Judd",
    "bio" => "Blanditiis nesciunt nesciunt voluptatem qui facilis nemo quod excepturi ut.",
    "birthdate" => "1976-05-25",
    "country_code" => "38",
    "date_joined" => "2019-05-03T18:23:29.414351Z",
    "email" => "litzy.beatty@hayes.info",
    "enable_push_notifications" => false,
    "first_name" => "Loy",
    "last_name" => "Hills",
    "phone" => "9774759105",
    "prefered_radius" => 1,
    "sex" => "m",
    "user_real_location" => nil,
    "user_safe_location" => nil,
    "user_tags" => [],
    "username" => "user",
    "password" => "PASSWORD",
    "verified_phone" => ""
  }

  describe "user" do
    setup [:create_users]

    test "can reset password", %{conn: conn, tokens: tokens} do
      token = hd(tokens)

      conn
      |> post(Routes.account_path(conn, :password_reset, email: token.user.email))
      |> response(200)

      [change_password] = Users.get_change_password_by_user(token.user.id)
      otp = change_password.hash

      conn
      |> post(
        Routes.account_path(conn, :change_password,
          email: token.user.email,
          password: "NewPassword42!",
          otp: otp
        )
      )
      |> response(200)

      conn
      |> post(
        Routes.token_path(conn, :create_token,
          username: token.user.username,
          password: "NewPassword42!"
        )
      )
      |> response(200)
    end
  end

  describe "email verification" do
    test "with valid params", %{conn: conn} = _context do
      use_cassette "authy_sms" do
        conn
        |> post(Routes.user_path(conn, :create), @valid_params)
        |> response(200)
      end

      user = Users.get_by_username("user")

      conn
      |> get("/api/email-verification?email=#{user.email}&token=#{user.verified_email}")
      |> response(200)

      user = Users.get_by_username("user")
      assert user.verified_email == user.email
    end

    test "with invalid params", %{conn: conn} = _context do
      use_cassette "authy_sms" do
        conn
        |> post(Routes.user_path(conn, :create), @valid_params)
        |> response(200)
      end

      user = Users.get_by_username("user")
      refute user.verified_email == "false"

      conn
      |> get("/api/email-verification?email=#{user.email}&token=BAD_TOKEN")
      |> response(200)

      user = Users.get_by_username("user")
      refute user.verified_email == user.email
    end
  end

  defmodule Stubs.PhoneVerification.Ok do
    def check(params) do
      send(self(), {__MODULE__, :check, params})
      {:ok, %{}}
    end
  end

  defmodule Stubs.PhoneVerification.Error do
    def check(params) do
      send(self(), {__MODULE__, :check, params})
      {:error, %{message: "Invalid OTP"}}
    end
  end

  describe "phone verification" do
    setup do
      replace(PhoneVerification, Stubs.PhoneVerification.Ok)

      %{
        user: insert(:user, phone: "1234567890", verified_phone: nil)
      }
    end

    test "returns ok when verification passes", %{conn: conn, user: user} do
      assert %{"verified" => true} ==
               conn
               |> authenticate(user)
               |> post(Routes.account_path(conn, :phone_verification, %{"otp" => "0123"}))
               |> json_response(200)
    end

    test "returns error when verification doesn't pass", %{conn: conn, user: user} do
      replace(PhoneVerification, Stubs.PhoneVerification.Error)

      assert %{"verified" => false, "message" => "Invalid OTP"} ==
               conn
               |> authenticate(user)
               |> post(Routes.account_path(conn, :phone_verification, %{"otp" => "0123"}))
               |> json_response(200)
    end

    test "returns error when phone is already verified by another user", %{conn: conn, user: user} do
      insert(:user, phone: "1234567890", verified_phone: "1234567890")

      assert %{
               "verified" => false,
               "message" => "This phone number is already taken",
               "reason" => "duplicate_phone_number"
             } ==
               conn
               |> authenticate(user)
               |> post(Routes.account_path(conn, :phone_verification, %{"otp" => "0123"}))
               |> json_response(200)
    end
  end

  defp create_users(_context) do
    tokens =
      for _ <- 1..10 do
        phone = Enum.random(100_000..19999) |> to_string()
        user = insert(:user, phone: phone, verified_phone: phone)
        insert(:auth_token, user: user)
      end

    {:ok, %{tokens: tokens}}
  end
end
