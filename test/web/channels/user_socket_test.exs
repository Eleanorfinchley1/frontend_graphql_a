defmodule Web.UserSocketTest do
  use Web.ChannelCase, async: true
  alias BillBored.User

  describe "connect" do
    test "with valid token" do
      %User.AuthToken{user: %User{} = user, key: token} = insert(:auth_token)

      {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

      assert socket.assigns.user.id == user.id
      assert socket.id == "user_socket:#{user.id}"
    end

    test "with invalid token" do
      assert :error == connect(Web.UserSocket, %{"token" => "invalid"})
    end

    test "without a token" do
      assert :error == connect(Web.UserSocket, %{})
    end

    test "user is banned" do
      banned_user = insert(:user, banned?: true)
      %User.AuthToken{key: token} = insert(:auth_token, user: banned_user)
      assert :error == connect(Web.UserSocket, %{"token" => token})
    end
  end
end
