defmodule Web.TokenControllerTest do
  use Web.ConnCase, async: true
  alias BillBored.User

  @password "randompassword"

  describe "create_token" do
    test "with valid username, phone verified", %{conn: conn} do
      user =
        insert(:user)
        |> User.update_changeset(%{password: @password})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "complete"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, username: user.username, password: @password))
        |> doc()
        |> json_response(200)
    end

    test "with valid username, phone not verified", %{conn: conn} do
      user =
        insert(:user, verified_phone: nil)
        |> User.update_changeset(%{password: @password})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "phone_verification_required"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, username: user.username, password: @password))
        |> doc()
        |> json_response(200)
    end

    test "with invalid username", %{conn: conn} do
      conn
      |> post(Routes.token_path(conn, :create_token, username: "wrong", password: @password))
      |> doc()
      |> response(404)
    end

    test "with invalid email", %{conn: conn} do
      conn
      |> post(Routes.token_path(conn, :create_token, email: "email", password: @password))
      |> response(404)
    end

    test "with valid email, phone not verified", %{conn: conn} do
      user =
        insert(:user, verified_phone: nil)
        |> User.update_changeset(%{password: @password})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "phone_verification_required"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, email: user.email, password: @password))
        |> json_response(200)
    end

    test "with valid email, phone verified", %{conn: conn} do
      user =
        insert(:user)
        |> User.update_changeset(%{password: @password})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "complete"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, email: user.email, password: @password))
        |> doc()
        |> json_response(200)
    end

    test "with invalid password", %{conn: conn} do
      user =
        insert(:user)
        |> User.update_changeset(%{password: @password})
        |> Repo.update!()

      user
      |> Ecto.Changeset.change(%{verified_phone: user.phone})
      |> Repo.update()

      conn
      |> post(Routes.token_path(conn, :create_token, email: user.email, password: "password"))
      |> response(404)
    end

    test "creates followings for user if not initialized", %{conn: conn} do
      recommendation = insert(:user_recommendation)

      %{id: user_id} = user =
        insert(:user)
        |> User.update_changeset(%{password: @password})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "complete"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, username: user.username, password: @password))
        |> doc()
        |> json_response(200)

      assert [%{id: ^user_id}] = BillBored.Users.list_followers(recommendation.user.id)
    end

    test "does not create followings for user if already initialized", %{conn: conn} do
      recommendation = insert(:user_recommendation)

      user =
        insert(:user)
        |> User.update_changeset(%{password: @password, flags: %{"autofollow" => "done"}})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "complete"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, username: user.username, password: @password))
        |> doc()
        |> json_response(200)

      assert [] == BillBored.Users.list_followers(recommendation.user.id)
    end

    test "restricts access to newly registered user", %{conn: conn} do
      user =
        insert(:user)
        |> User.update_changeset(%{password: @password, flags: %{}})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "complete",
        "access" => "restricted"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, username: user.username, password: @password))
        |> json_response(200)

      assert %{flags: %{
        "access" => "restricted",
        "restriction_reason" => "Thank you for your interest in the service. We will invite you in as soon as more room is available!"
      }} = Repo.get!(User, user.id)
    end

    test "does not restrict access to whitelisted user", %{conn: conn} do
      user =
        insert(:user)
        |> User.update_changeset(%{password: @password, flags: %{"access" => "granted"}})
        |> Repo.update!()

      assert %{
        "token" => _,
        "registration_status" => "complete",
        "access" => "granted"
      } =
        conn
        |> post(Routes.token_path(conn, :create_token, username: user.username, password: @password))
        |> json_response(200)

      assert %{flags: %{"access" => "granted"}} = Repo.get!(User, user.id)
    end
  end
end
