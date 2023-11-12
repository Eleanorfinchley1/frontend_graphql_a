defmodule BillBored.Absent.UserPointsTest do
  use BillBored.DataCase, async: true
  alias BillBored.UserPoints

  setup [:load_config]

  describe "doesn't give absent_points" do
    test "when user just signed up", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 + 2))
      {0, []} = UserPoints.reduce_during_absent(user.id)
    end

    test "when user attended in chatting recently", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      insert(:chat_message, room: room, user: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 + 2))
      {0, []} = UserPoints.reduce_during_absent(user.id)
    end

    test "when user created the dropchat stream recently", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      insert(:dropchat_stream, dropchat: room, admin: user, status: "finished", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 + 2))
      {0, []} = UserPoints.reduce_during_absent(user.id)
    end

    test "when user created reaction in dopchat stream recently", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      dropchat_stream = insert(:dropchat_stream, dropchat: room, admin: user, status: "finished", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:dropchat_stream_reaction, stream: dropchat_stream, user: user, type: "like", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 + 2))
      {0, []} = UserPoints.reduce_during_absent(user.id)
    end

    test "when user speaked in dopchat stream recently", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      dropchat_stream = insert(:dropchat_stream, dropchat: room, admin: user, status: "finished", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:dropchat_stream_speaker, stream: dropchat_stream, user: user, inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 + 2))
      {0, []} = UserPoints.reduce_during_absent(user.id)
    end

    test "when user created in livestream recently", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:livestream, owner: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 + 2))
      {0, []} = UserPoints.reduce_during_absent(user.id)
    end

    test "when user commented in livestream recently", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      livestream = insert(:livestream, owner: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:livestream_comment, livestream: livestream, author: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 + 2))
      {0, []} = UserPoints.reduce_during_absent(user.id)
    end

    test "when user voted the comments in livestream recently", %{config: config} do
    end

    test "when user viewed the livestream recently", %{config: config} do
    end

    test "when user voted the livestream recently", %{config: config} do
    end
  end

  describe "gives absent_points successfully" do
    test "when user signed up long ago", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      {1, [audit]} = UserPoints.reduce_during_absent(user.id)
      assert audit.points == -round(config.signup_points * config.absent_percentage / 100)
      assert audit.reason == "absent"
    end

    test "when user didn't attend to chatting for long", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      message = insert(:chat_message, room: room, user: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      {1, [audit]} = UserPoints.reduce_during_absent(user.id)
      assert audit.points == -round(config.signup_points * config.absent_percentage / 100)
      assert audit.reason == "absent"
    end

    test "when user didn't attend to dropchat stream for long", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      insert(:dropchat_stream, dropchat: room, admin: user, status: "finished", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      {1, [audit]} = UserPoints.reduce_during_absent(user.id)
      assert audit.points == -round(config.signup_points * config.absent_percentage / 100)
      assert audit.reason == "absent"
    end

    test "when user didn't react to dropchat stream for long", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      dropchat_stream = insert(:dropchat_stream, dropchat: room, admin: user, status: "finished", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:dropchat_stream_reaction, stream: dropchat_stream, user: user, type: "like", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      {1, [audit]} = UserPoints.reduce_during_absent(user.id)
      assert audit.points == -round(config.signup_points * config.absent_percentage / 100)
      assert audit.reason == "absent"
    end

    test "when user didn't speak to dropchat stream for long", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      room = create_chatroom(user)
      dropchat_stream = insert(:dropchat_stream, dropchat: room, admin: user, status: "finished", inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:dropchat_stream_speaker, stream: dropchat_stream, user: user, inserted_at: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      {1, [audit]} = UserPoints.reduce_during_absent(user.id)
      assert audit.points == -round(config.signup_points * config.absent_percentage / 100)
      assert audit.reason == "absent"
    end

    test "when user didn't create to livestream for long", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:livestream, owner: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      {1, [audit]} = UserPoints.reduce_during_absent(user.id)
      assert audit.points == -round(config.signup_points * config.absent_percentage / 100)
      assert audit.reason == "absent"
    end

    test "when user didn't comment to livestream for long", %{config: config} do
      user = signup_user(config, DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      livestream = insert(:livestream, owner: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      insert(:livestream_comment, livestream: livestream, author: user, created: DateTime.add(DateTime.utc_now(), - config.absent_days * 24 * 3600 - 2))
      {1, [audit]} = UserPoints.reduce_during_absent(user.id)
      assert audit.points == -round(config.signup_points * config.absent_percentage / 100)
      assert audit.reason == "absent"
    end

    test "when user didn't vote to livestream comment for long", %{config: config} do
    end

    test "when user didn't view the livestream for long", %{config: config} do
    end

    test "when user didn't vote the livestream for long", %{config: config} do
    end
  end

  defp load_config(_context) do
    {:ok, config: %{
      signup_points: Application.get_env(:billbored, UserPoints)[:signup_points],
      signup_points_available_hours: Application.get_env(:billbored, UserPoints)[:signup_points_available_hours],
      absent_days: Application.get_env(:billbored, UserPoints)[:absent_days],
      absent_percentage: Application.get_env(:billbored, UserPoints)[:absent_percentage]
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

  defp create_chatroom(user) do
    room = insert(:chat_room, chat_type: "dropchat")
    insert(:chat_room_membership, room: room, user: user, role: "admin")
    insert(:chat_room_administratorship, room: room, user: user)
    room
  end
end
