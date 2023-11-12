defmodule BillBored.Notifications.AreaNotificationsTest do
  use BillBored.DataCase, async: true

  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotifications

  defp time(shift), do: Timex.shift(DateTime.utc_now(), shift)
  defp date(shift), do: Timex.shift(Timex.today(), shift)

  describe "find_matching/2" do
    setup do
      %{
        location: %BillBored.Geo.Point{lat: 51.5, long: -0.12},
        close_location: %BillBored.Geo.Point{lat: 51.504232, long: -0.119175},
        far_location: %BillBored.Geo.Point{lat: 52.5, long: -0.119175}
      }
    end

    test "finds area notification when location is within radius", %{
      location: location,
      close_location: close_location
    } do
      %{id: notification_id} =
        insert(:area_notification, expires_at: time(days: 5), location: location, radius: 500)

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(insert(:user).id, close_location)
    end

    test "doesn't find area notification when location is outside of radius", %{
      location: location,
      far_location: far_location
    } do
      insert(:area_notification, expires_at: time(days: 5), location: location, radius: 500)

      refute AreaNotifications.find_matching(insert(:user).id, far_location)
    end

    test "finds area notification without expiration date", %{
      location: location,
      close_location: close_location
    } do
      %{id: notification_id} =
        insert(:area_notification, expires_at: nil, location: location, radius: 500)

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(insert(:user).id, close_location)
    end

    test "doesn't find area notification when it's expired", %{
      location: location,
      close_location: close_location
    } do
      insert(:area_notification, expires_at: time(days: -5), location: location, radius: 500)

      refute AreaNotifications.find_matching(insert(:user).id, close_location)
    end

    test "doesn't find area notification when user already received it", %{
      location: location,
      close_location: close_location
    } do
      user = insert(:user)
      area_notification = insert(:area_notification, location: location, radius: 500)
      insert(:area_notification_reception, user: user, area_notification: area_notification)

      refute AreaNotifications.find_matching(user.id, close_location)
    end

    test "finds area notification when another user already received it", %{
      location: location,
      close_location: close_location
    } do
      %{id: notification_id} =
        area_notification = insert(:area_notification, location: location, radius: 500)

      insert(:area_notification_reception, area_notification: area_notification)

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(insert(:user).id, close_location)
    end

    test "finds area notification when user already received another notification", %{
      location: location,
      close_location: close_location
    } do
      user = insert(:user)
      %{id: notification_id} = insert(:area_notification, location: location, radius: 500)

      insert(:area_notification_reception, user: user)

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(user.id, close_location)
    end

    test "finds most recently created area notification", %{
      location: location,
      close_location: close_location
    } do
      %{id: notification_id} =
        insert(:area_notification, expires_at: time(days: 5), location: location, radius: 500)

      insert(:area_notification,
        expires_at: time(days: 5),
        inserted_at: time(days: -3),
        location: location,
        radius: 500
      )

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(insert(:user).id, close_location)
    end

    test "finds area notification matching user's sex (sex = F)", %{
      location: location,
      close_location: close_location
    } do
      %{id: notification_id} =
        insert(:area_notification,
          expires_at: time(days: 5),
          sex: "F",
          inserted_at: time(days: -5),
          location: location,
          radius: 500
        )

      insert(:area_notification,
        expires_at: time(days: 5),
        sex: "M",
        location: location,
        radius: 500
      )

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(insert(:user, sex: "F").id, close_location)
    end

    test "finds area notification matching user's age (min_age = 18, max_age = 42)", %{
      location: location,
      close_location: close_location
    } do
      %{id: notification_id} =
        insert(:area_notification,
          expires_at: time(days: 5),
          max_age: 42,
          min_age: 18,
          location: location,
          radius: 500
        )

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(
                 insert(:user, birthdate: date(years: -38)).id,
                 close_location
               )
    end

    test "doesn't find area notification not matching user's age (min_age = 18, max_age = 42)", %{
      location: location,
      close_location: close_location
    } do
      insert(:area_notification,
        expires_at: time(days: 5),
        max_age: 42,
        min_age: 18,
        location: location,
        radius: 500
      )

      refute AreaNotifications.find_matching(
               insert(:user, birthdate: date(years: -45)).id,
               close_location
             )

      refute AreaNotifications.find_matching(
               insert(:user, birthdate: date(years: -16)).id,
               close_location
             )
    end

    test "finds area notification matching user's interests", %{
      location: location,
      close_location: close_location
    } do
      %{id: notification_id} =
        insert(:area_notification,
          expires_at: time(days: 5),
          categories: ["food"],
          location: location,
          radius: 500
        )

      user = insert(:user)
      soup = insert(:interest, hashtag: "soup")
      food = insert(:interest_category, name: "food")
      insert(:interest_category_interest, interest: soup, interest_category: food)
      insert(:user_interest, user: user, interest: soup)

      assert %AreaNotification{id: ^notification_id} =
               AreaNotifications.find_matching(user.id, close_location)
    end

    test "doesn't find area notification not matching user's interests", %{
      location: location,
      close_location: close_location
    } do
      insert(:area_notification,
        expires_at: time(days: 5),
        categories: ["food"],
        location: location,
        radius: 500
      )

      refute AreaNotifications.find_matching(insert(:user).id, close_location)
    end
  end

  describe "get_scheduled" do
    test "returns scheduled area notifications" do
      [%{id: an1_id} = an1, %{id: an2_id} = an2, _an3] = insert_list(3, :area_notification)

      notification = insert(:notification, verb: "area_notifications:scheduled")
      insert(:notification_area_notification, notification: notification, area_notification: an1)
      insert(:notification_area_notification, notification: notification, area_notification: an2)

      sorted_result =
        AreaNotifications.get_scheduled(notification.recipient_id)
        |> Enum.sort_by(&(&1.id))

      assert [%{id: ^an1_id}, %{id: ^an2_id}] = sorted_result
    end

    test "does not return old notifications" do
      [an1, an2] = insert_list(2, :area_notification)

      notification = insert(:notification, verb: "area_notifications:scheduled", timestamp: Timex.shift(DateTime.utc_now(), days: -2))
      insert(:notification_area_notification, notification: notification, area_notification: an1)
      insert(:notification_area_notification, notification: notification, area_notification: an2)

      assert [] == AreaNotifications.get_scheduled(notification.recipient_id)
    end

    test "does not return expired area notifications" do
      %{id: an1_id} = an1 = insert(:area_notification)
      an2 = insert(:area_notification, expires_at: Timex.shift(DateTime.utc_now(), days: -5))

      notification = insert(:notification, verb: "area_notifications:scheduled")
      insert(:notification_area_notification, notification: notification, area_notification: an1)
      insert(:notification_area_notification, notification: notification, area_notification: an2)

      assert [%{id: ^an1_id}] = AreaNotifications.get_scheduled(notification.recipient_id)
    end
  end
end
