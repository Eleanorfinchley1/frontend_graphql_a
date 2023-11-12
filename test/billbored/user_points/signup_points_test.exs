defmodule BillBored.Signup.UserPointsTest do
  use BillBored.DataCase, async: true
  alias BillBored.UserPoints

  setup [:load_config]

  # //////////////////////////////////////////////////////////////////////////////////////
  # Signup points is highly consumable rather than other type.
  # e.g:) singup_points <= 10, peak_points <= 20, streaming <= -5 : expired_points = 5
  #       singup_points <= 10, peak_points <= 20, streaming <= -20 : expired_points = 0
  describe "expires the signup_points" do
    test "of a user not expired", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.signup_points_available_hours * 3600 + 1))
      {0, []} = UserPoints.expire_signup_points(user.id)
      assert config.signup_points == UserPoints.get(user.id).stream_points
    end

    test "of the expired user who doesn't recieved any points", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.signup_points_available_hours * 3600))
      {1, [audit]} = UserPoints.expire_signup_points(user.id)
      assert audit.points == -config.signup_points
      assert audit.reason == "signup_expire"
      assert 0 == UserPoints.get(user.id).stream_points
    end

    test "of the expired user who recieved and spent 1 point", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.signup_points_available_hours * 3600))
      UserPoints.create_audit(%{user_id: user.id, points: 1, p_type: "stream", reason: "anticipation"})
      UserPoints.create_audit(%{user_id: user.id, points: -1, p_type: "stream", reason: "streaming"})
      {1, [audit]} = UserPoints.expire_signup_points(user.id)
      assert audit.points == -config.signup_points + 1
      assert audit.reason == "signup_expire"
      assert 1 == UserPoints.get(user.id).stream_points
    end

    test "of the expired user who recieved and spent (1 + signup_points) point", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.signup_points_available_hours * 3600))
      UserPoints.create_audit(%{user_id: user.id, points: 1 + config.signup_points, p_type: "stream", reason: "anticipation"})
      UserPoints.create_audit(%{user_id: user.id, points: -1 - config.signup_points, p_type: "stream", reason: "streaming"})
      {1, [audit]} = UserPoints.expire_signup_points(user.id)
      assert audit.points == 0
      assert audit.reason == "signup_expire"
      assert config.signup_points == UserPoints.get(user.id).stream_points
    end
  end

  defp load_config(_context) do
    {:ok, config: %{
      signup_points: Application.get_env(:billbored, UserPoints)[:signup_points],
      signup_points_available_hours: Application.get_env(:billbored, UserPoints)[:signup_points_available_hours]
    }}
  end

  defp signup_user(config, joined \\ DateTime.utc_now()) do
    user = insert(:user, date_joined: joined)
    {:ok, audit} = UserPoints.give_signup_points(user.id, joined)
    assert audit.points == config.signup_points
    assert audit.user_id == user.id
    assert audit.p_type == "stream"
    assert audit.reason == "signup"
    user
  end
end
