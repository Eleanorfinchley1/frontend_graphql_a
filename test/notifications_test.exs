defmodule NotificationsTest do
  use BillBored.DataCase, async: true

  import Ecto.Query

  defp sorted(notifications) do
    Enum.sort_by(notifications, fn
      %Pigeon.APNS.Notification{} -> 0
      %Pigeon.FCM.Notification{} -> 1
    end)
  end

  describe "process_chat_tagged/1" do
    setup do
      [r1, r2] = receivers = insert_list(2, :user, enable_push_notifications: true)

      receivers_devices = [
        insert(:user_device, user: r1, platform: "ios"),
        insert(:user_device, user: r2, platform: "android")
      ]

      room = insert(:chat_room)
      message = insert(:chat_message, room: room)
      insert(:chat_room_membership, user: r1, room: room)
      insert(:chat_room_membership, user: r2, room: room)

      receivers = Repo.preload(receivers, [:devices]) |> Enum.sort_by(& &1.id)

      %{room: room, message: message, receivers: receivers, receivers_devices: receivers_devices}
    end

    test "creates correct notitication push jobs", %{
      room: room,
      message: message,
      receivers: [r1, r2],
      receivers_devices: [_d1, _d2]
    } do
      tagger = insert(:user)

      memberships =
        BillBored.Chat.Room.Membership
        |> where(room_id: ^room.id)
        |> where([ru], ru.userprofile_id in [^r1.id, ^r2.id])
        |> preload([ru], user: :devices)
        |> Repo.all()

      Notifications.process_chat_tagged(
        tagger: tagger,
        message: message,
        room: room,
        receivers: memberships
      )

      %{id: n1_id} =
        from(n in BillBored.Notification, where: n.recipient_id == ^r1.id) |> Repo.one()

      %{id: n2_id} =
        from(n in BillBored.Notification, where: n.recipient_id == ^r2.id) |> Repo.one()

      job_payload =
        from(j in "rihanna_jobs",
          select: j.term,
          order_by: [{:desc, j.id}],
          limit: 1
        )
        |> Repo.one()
        |> :erlang.binary_to_term()

      assert {Queue.PigeonPushJob, notifications} = job_payload
      [jn1, jn2] = sorted(notifications)

      assert %Pigeon.APNS.Notification{payload: %{"notification_id" => ^n1_id}} = jn1
      assert %Pigeon.FCM.Notification{payload: %{"data" => %{"notification_id" => ^n2_id}}} = jn2
    end
  end
end
