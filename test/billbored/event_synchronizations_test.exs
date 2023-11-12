defmodule BillBored.EventSynchronizationTest do
  use BillBored.DataCase, async: true
  alias BillBored.EventSynchronizations

  use Timex

  describe "complete/1" do
    test "sets status to 'completed'" do
      es = insert(:event_synchronization, status: "pending")
      {:ok, completed_es} = EventSynchronizations.complete(es)
      assert %{status: "completed"} = completed_es
    end
  end

  describe "fail/1" do
    test "sets status to 'failed'" do
      es = insert(:event_synchronization, status: "pending")
      {:ok, failed_es} = EventSynchronizations.fail(es)
      assert %{status: "failed"} = failed_es
    end
  end

  describe "count_since/1" do
    setup do
      location = %BillBored.Geo.Point{long: -74.0059662, lat: 40.7142715}
      close_location = %BillBored.Geo.Point{long: -73.994817, lat: 40.723952}
      remote_location = %BillBored.Geo.Point{long: -73.970151, lat: 40.675303}

      insert(:event_synchronization, location: location, radius: 3210.123, status: "pending")
      insert(:event_synchronization, location: location, radius: 6000, status: "pending")
      insert_list(3, :event_synchronization, location: location, radius: 3000, status: "completed")
      insert(:event_synchronization, location: location, radius: 4000, status: "failed")

      insert(:event_synchronization, location: location, radius: 4000, started_at: ~U[2003-12-31 23:54:00.000000Z], status: "failed")
      insert(:event_synchronization, location: location, radius: 7000, started_at: ~U[2003-12-31 23:54:00.000000Z], status: "completed")
      insert(:event_synchronization, location: location, radius: 2000, started_at: ~U[2003-12-31 23:54:00.000000Z], status: "pending")

      %{location: location, close_location: close_location, remote_location: remote_location}
    end

    test "returns counts by status", %{close_location: location} do
      recent_since = Timex.shift(DateTime.utc_now(), minutes: -3)
      old_since = ~U[2000-01-01 00:00:00.000000Z]

      assert %{pending_count: 2, failed_count: 1, completed_count: 3} =
               EventSynchronizations.count_recent("meetup", {location, 1000}, recent_since)

      assert %{pending_count: 3, failed_count: 2, completed_count: 4} =
               EventSynchronizations.count_recent("meetup", {location, 1000}, old_since)
    end

    test "counts only synchronizations in radius", %{remote_location: location} do
      recent_since = Timex.shift(DateTime.utc_now(), minutes: -3)
      old_since = ~U[2000-01-01 00:00:00.000000Z]

      assert %{pending_count: 1, failed_count: 0, completed_count: 0} =
               EventSynchronizations.count_recent("meetup", {location, 500}, recent_since)

      assert %{pending_count: 1, failed_count: 0, completed_count: 1} =
               EventSynchronizations.count_recent("meetup", {location, 500}, old_since)
    end
  end

  describe "delete_old" do
    setup do
      location = %BillBored.Geo.Point{long: -74.0059662, lat: 40.7142715}

      insert(:event_synchronization, location: location, status: "failed")
      insert(:event_synchronization, location: location, status: "completed")
      insert(:event_synchronization, location: location, status: "pending")

      insert(:event_synchronization, location: location, started_at: ~U[2003-12-31 23:54:00.000000Z], status: "failed")
      insert(:event_synchronization, location: location, event_provider: "eventful", started_at: ~U[2003-12-31 23:54:00.000000Z], status: "completed")
      insert(:event_synchronization, location: location, started_at: ~U[2003-12-31 23:54:00.000000Z], status: "pending")

      %{location: location}
    end

    test "deletes old event synchronization records", %{location: location} do
      recent_since = Timex.shift(DateTime.utc_now(), minutes: -3)
      old_since = ~U[2000-01-01 00:00:00.000000Z]

      EventSynchronizations.delete_old("meetup", recent_since)

      assert %{pending_count: 1, failed_count: 1, completed_count: 1} =
               EventSynchronizations.count_recent("meetup", {location, 500}, old_since)

      assert %{completed_count: 1} =
               EventSynchronizations.count_recent("eventful", {location, 500}, old_since)

      EventSynchronizations.delete_old("meetup", DateTime.utc_now())

      assert %{pending_count: 0, failed_count: 0, completed_count: 0} =
               EventSynchronizations.count_recent("meetup", {location, 500}, old_since)

      EventSynchronizations.delete_old("eventful", DateTime.utc_now())

      assert %{completed_count: 0} =
               EventSynchronizations.count_recent("eventful", {location, 500}, old_since)
    end
  end
end
