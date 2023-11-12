defmodule BillBored.Notifications.AreaNotifications.TimetableEntriesTest do
  use BillBored.DataCase, async: true

  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotifications.TimetableEntries
  alias BillBored.Notifications.AreaNotifications.TimetableEntry
  alias BillBored.Notifications.AreaNotifications.TimetableRun

  describe "start_pending_runs basic" do
    setup do
      entry = insert(:area_notifications_timetable_entry, time: ~T[23:30:00], any_category: true)
      area_notification = insert(:area_notification, timezone: "PST")

      %{
        entry: entry,
        area_notification: area_notification
      }
    end

    test "does not match notification before its time" do
      assert {:ok, []} = TimetableEntries.start_pending_runs(~U[2021-02-03 06:29:45Z])
    end

    test "matches notification after its time", %{
      area_notification: %{id: area_notification_id}
    } do
      assert {:ok,
              [
                %TimetableRun{
                  area_notification: %AreaNotification{id: ^area_notification_id},
                  timetable_entry: %TimetableEntry{time: ~T[23:30:00]},
                  timestamp: timestamp
                }
              ]} = TimetableEntries.start_pending_runs(~U[2021-02-03 07:31:45Z])

      assert timestamp == DateTime.to_unix(~U[2021-02-03 00:00:00Z])
    end

    test "doesn't match notification when run already exists", %{
      entry: entry,
      area_notification: area_notification
    } do
      insert(:area_notifications_timetable_run,
        timetable_entry: entry,
        area_notification: area_notification,
        timestamp: DateTime.to_unix(~U[2021-02-03 00:00:00Z])
      )

      assert {:ok, []} = TimetableEntries.start_pending_runs(~U[2021-02-03 07:31:45Z])
    end
  end

  describe "start_pending_runs categories" do
    setup do
      entry =
        insert(:area_notifications_timetable_entry, time: ~T[12:00:00], categories: ["food"])

      insert(:area_notifications_timetable_entry, time: ~T[11:00:00], categories: ["cats"])

      area_notification = insert(:area_notification, timezone: "UTC", categories: ["food"])
      insert(:area_notification, categories: ["cars"])

      %{
        entry: entry,
        area_notification: area_notification
      }
    end

    test "starts only runs for notifications with matching categories", %{
      area_notification: %{id: area_notification_id}
    } do
      assert {:ok,
              [
                %TimetableRun{
                  area_notification: %AreaNotification{id: ^area_notification_id},
                  timetable_entry: %TimetableEntry{time: ~T[12:00:00]},
                  timestamp: timestamp
                }
              ]} = TimetableEntries.start_pending_runs(~U[2021-02-03 12:05:00Z])

      assert timestamp == DateTime.to_unix(~U[2021-02-03 00:00:00Z])
    end
  end

  describe "start_pending_runs any categories" do
    setup do
      entry = insert(:area_notifications_timetable_entry, time: ~T[15:00:00], any_category: true)

      area_notification_food = insert(:area_notification, categories: ["food"])
      area_notification_cars = insert(:area_notification, categories: ["cars"])

      %{
        entry: entry,
        area_notification_food: area_notification_food,
        area_notification_cars: area_notification_cars
      }
    end

    test "starts only runs for notifications with matching categories", %{
      area_notification_food: %{id: area_notification_food_id},
      area_notification_cars: %{id: area_notification_cars_id}
    } do
      assert {:ok, runs} = TimetableEntries.start_pending_runs(~U[2021-02-03 15:05:00Z])

      assert [
               %TimetableRun{
                 area_notification: %AreaNotification{id: ^area_notification_food_id},
                 timetable_entry: %TimetableEntry{time: ~T[15:00:00]}
               },
               %TimetableRun{
                 area_notification: %AreaNotification{id: ^area_notification_cars_id},
                 timetable_entry: %TimetableEntry{time: ~T[15:00:00]}
               }
             ] =
               Enum.sort_by(runs, fn %{area_notification_id: area_notification_id} ->
                 area_notification_id
               end)
    end
  end

  describe "start_pending_runs multiple entries" do
    setup do
      entry1 = insert(:area_notifications_timetable_entry, time: ~T[12:00:00], any_category: true)
      entry2 = insert(:area_notifications_timetable_entry, time: ~T[15:00:00], any_category: true)

      area_notification = insert(:area_notification)

      %{
        entries: [entry1, entry2],
        area_notification: area_notification
      }
    end

    test "starts runs for all matching entries", %{
      area_notification: %{id: area_notification_id}
    } do
      assert {:ok, runs} = TimetableEntries.start_pending_runs(~U[2021-02-03 15:05:00Z])

      assert [
               %TimetableRun{
                 area_notification: %AreaNotification{id: ^area_notification_id},
                 timetable_entry: %TimetableEntry{time: ~T[12:00:00]}
               },
               %TimetableRun{
                 area_notification: %AreaNotification{id: ^area_notification_id},
                 timetable_entry: %TimetableEntry{time: ~T[15:00:00]}
               }
             ] =
               Enum.sort_by(runs, fn %{timetable_entry_id: timetable_entry_id} ->
                 timetable_entry_id
               end)
    end
  end

  describe "group_user_runs" do
    test "" do
      assert [
        {MapSet.new([1]), [:run2, :run1]},
        {MapSet.new([4]), [:run4, :run1]},
        {MapSet.new([2]), [:run3, :run2]},
        {MapSet.new([3]), [:run2]}
      ] ==
        TimetableEntries.group_user_runs([
          {:run1, MapSet.new([1, 4])},
          {:run2, MapSet.new([1, 2, 3])},
          {:run3, MapSet.new([2])},
          {:run4, MapSet.new([4])},
        ])
    end
  end
end
