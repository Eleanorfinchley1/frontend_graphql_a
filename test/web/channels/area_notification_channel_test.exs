defmodule Web.AreaNotificationChannelTest do
  use Web.ChannelCase

  import Ecto.Query

  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotificationReception
  alias BillBored.Notifications.AreaNotifications.MatchData

  setup do
    user = insert(:user, sex: "M")
    %{key: token} = insert(:auth_token, user: user)
    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

    %{user: user, socket: socket}
  end

  describe "join lobby" do
    test "with valid geometry", %{socket: socket} do
      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:lobby", %{"geometry" => user_location})

      assert_push("area:change", payload)

      assert %{
               area: %{
                 location: %{
                   coordinates: [40.5, -50.0],
                   crs: %{properties: %{name: "EPSG:4326"}, type: "name"},
                   type: "Point"
                 },
                 location_geohash: "dzhq",
                 notifications_channel: "area_notifications:dzhq"
               }
             } == payload
    end

    test "with invalid geometry", %{socket: socket} do
      {:error, %{"reason" => "invalid_params"}} =
        subscribe_and_join(socket, "area_notifications:lobby", %{"geometry" => [40.5, -50.0]})

      refute_push("area:change", _payload)
    end
  end

  describe "join" do
    test "with valid geohash and location", %{socket: socket} do
      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}
      geohash = Geohash.encode(40.5, -50.0, 4)

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      refute_push("area:change", _payload)
    end

    test "with invalid geometry", %{socket: socket} do
      geohash = Geohash.encode(40.5, -50.0, 4)

      {:error, %{"reason" => "invalid_params"}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => [40.5, -50.0]})

      refute_push("area:change", _payload)
    end

    test "with geohash and location not matching", %{socket: socket} do
      user_location = %{"type" => "Point", "coordinates" => [51.4, -0.5]}
      geohash = Geohash.encode(40.5, -50.0, 4)

      {:error, %{"reason" => "invalid_params"}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      refute_push("area:change", _payload)
    end

    test "pushes matching notification to channel", %{user: %{id: user_id}, socket: socket} do
      %{id: business_id} = business_account = insert(:business_account)

      owner = insert(:user)

      image =
        insert(:upload,
          owner: owner,
          media_type: "image",
          media: %{file_name: "test.jpg", updated_at: nil}
        )

      %{id: area_notification_id} =
        notification =
        insert(:area_notification,
          location: %BillBored.Geo.Point{lat: 55.5, long: -0.12},
          radius: 500,
          owner: owner,
          business: business_account,
          image_media_key: image.media_key
        )

      user_location = %{"type" => "Point", "coordinates" => [55.504232, -0.119175]}
      geohash = Geohash.encode(55.504232, -0.119175, 4)

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      assert_push("notification:broadcast", payload)
      refute_push("notification:scheduled", _payload)

      %{id: owner_id, username: owner_username} = owner
      %{title: title, message: message, radius: radius} = notification
      image_url = BillBored.Uploads.File.url({image.media, image}, :original)

      assert %{
               owner: %{
                 id: ^owner_id,
                 username: ^owner_username
               },
               business: %{
                 id: ^business_id
               },
               location: %{
                 coordinates: [55.5, -0.12],
                 crs: %{properties: %{name: "EPSG:4326"}, type: "name"},
                 type: "Point"
               },
               image_url: ^image_url,
               logo_url: "",
               title: ^title,
               message: ^message,
               radius: ^radius
             } = payload

      assert %{user_id: ^user_id, area_notification_id: ^area_notification_id} =
               from(anr in AreaNotificationReception, where: anr.user_id == ^user_id)
               |> Repo.one()

      assert %{receivers_count: 1} = Repo.get!(AreaNotification, notification.id)
    end

    test "pushes scheduled area notifications to the channel", %{
      user: user,
      socket: socket
    } do
      %{id: business_id} = business_account = insert(:business_account)

      owner = insert(:user)

      image =
        insert(:upload,
          owner: owner,
          media_type: "image",
          media: %{file_name: "test.jpg", updated_at: nil}
        )

      area_notification =
        insert(:area_notification,
          location: %BillBored.Geo.Point{lat: 53.4, long: -28.0},
          radius: 500,
          owner: owner,
          business: business_account,
          image_media_key: image.media_key
        )

      user_location = %{"type" => "Point", "coordinates" => [55.504232, -0.119175]}
      geohash = Geohash.encode(55.504232, -0.119175, 4)

      notification = insert(:notification, recipient: user, verb: "area_notifications:scheduled")

      insert(:notification_area_notification,
        notification: notification,
        area_notification: area_notification
      )

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      assert_push("notification:scheduled", payload)

      %{id: owner_id, username: owner_username} = owner
      %{title: title, message: message, radius: radius} = area_notification
      image_url = BillBored.Uploads.File.url({image.media, image}, :original)

      assert %{
               area_notifications: [
                 %{
                   owner: %{
                     id: ^owner_id,
                     username: ^owner_username
                   },
                   business: %{
                     id: ^business_id
                   },
                   location: %{
                     coordinates: [53.4, -28.0],
                     crs: %{properties: %{name: "EPSG:4326"}, type: "name"},
                     type: "Point"
                   },
                   image_url: ^image_url,
                   logo_url: "",
                   title: ^title,
                   message: ^message,
                   radius: ^radius
                 }
               ]
             } = payload
    end
  end

  describe "location:update" do
    setup(%{socket: socket}) do
      user_location = %{"type" => "Point", "coordinates" => [40.5, -50.0]}

      geohash = Geohash.encode(40.5, -50.0, 4)

      {:ok, %{}, %Phoenix.Socket{} = new_socket} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      %{socket: new_socket, user_location: user_location}
    end

    test "does not push area:change when new location is in the same geohash", %{socket: socket} do
      new_location = %{"type" => "Point", "coordinates" => [40.4999936, -50.00145]}

      ref = push(socket, "location:update", %{"geometry" => new_location})
      assert_reply(ref, :ok, %{})

      refute_push("area:change", _payload)
    end

    test "pushes area:change when new location is in another geohash", %{socket: socket} do
      new_location = %{"type" => "Point", "coordinates" => [51.4, -0.5]}

      ref = push(socket, "location:update", %{"geometry" => new_location})
      assert_reply(ref, :ok, %{})

      assert_push("area:change", payload)

      assert %{
               area: %{
                 location: %{
                   coordinates: [51.4, -0.5],
                   crs: %{properties: %{name: "EPSG:4326"}, type: "name"},
                   type: "Point"
                 },
                 location_geohash: "gcps",
                 notifications_channel: "area_notifications:gcps"
               }
             } == payload
    end
  end

  describe "notify/1" do
    setup do
      owner = insert(:user)

      image =
        insert(:upload,
          owner: owner,
          media_type: "image",
          media: %{file_name: "test.jpg", updated_at: nil}
        )

      notification =
        insert(:area_notification,
          location: %BillBored.Geo.Point{lat: 51.5, long: -0.12},
          radius: 500,
          owner: owner,
          expires_at: ~U[2020-02-02 01:01:01Z],
          image_media_key: image.media_key
        )
        |> Repo.preload([:owner, :logo, :image])

      %{owner: owner, image: image, notification: notification}
    end

    test "pushes notification to user within radius", %{
      socket: socket,
      owner: owner,
      image: image,
      notification: notification
    } do
      user_location = %{"type" => "Point", "coordinates" => [51.504232, -0.119175]}
      geohash = Geohash.encode(51.504232, -0.119175, 4)

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      Web.AreaNotificationChannel.notify(notification, MatchData.new(notification))

      assert_push("notification:broadcast", payload)

      %{id: owner_id, username: owner_username} = owner
      %{title: title, message: message, radius: radius} = notification
      image_url = BillBored.Uploads.File.url({image.media, image}, :original)

      assert %{
               owner: %{
                 id: ^owner_id,
                 username: ^owner_username
               },
               location: %{
                 coordinates: [51.5, -0.12],
                 crs: %{properties: %{name: "EPSG:4326"}, type: "name"},
                 type: "Point"
               },
               image_url: ^image_url,
               logo_url: "",
               title: ^title,
               message: ^message,
               radius: ^radius
             } = payload
    end

    test "pushes business notification to user within radius", %{
      socket: socket,
      owner: owner,
      image: image
    } do
      %{id: business_id} = business_account = insert(:business_account)

      notification =
        insert(:area_notification,
          location: %BillBored.Geo.Point{lat: 51.5, long: -0.12},
          radius: 500,
          owner: owner,
          business: business_account,
          inserted_at: ~U[2010-01-01 01:01:01Z],
          expires_at: ~U[2020-02-02 20:20:20Z],
          image_media_key: image.media_key
        )
        |> Repo.preload([:owner, :business, :logo, :image])

      user_location = %{"type" => "Point", "coordinates" => [51.504232, -0.119175]}
      geohash = Geohash.encode(51.504232, -0.119175, 4)

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      Web.AreaNotificationChannel.notify(notification, MatchData.new(notification))

      assert_push("notification:broadcast", payload)

      %{id: owner_id, username: owner_username} = owner
      %{title: title, message: message, radius: radius} = notification
      image_url = BillBored.Uploads.File.url({image.media, image}, :original)

      assert %{
               owner: %{
                 id: ^owner_id,
                 username: ^owner_username
               },
               business: %{
                 id: ^business_id
               },
               location: %{
                 coordinates: [51.5, -0.12],
                 crs: %{properties: %{name: "EPSG:4326"}, type: "name"},
                 type: "Point"
               },
               image_url: ^image_url,
               logo_url: "",
               title: ^title,
               message: ^message,
               radius: ^radius,
               inserted_at: ~U[2010-01-01 01:01:01.000000Z],
               expires_at: ~U[2020-02-02 20:20:20.000000Z]
             } = payload
    end

    @tag slow: true
    test "updates receivers_count when notification is pushed", %{
      socket: socket,
      notification: notification
    } do
      user_location = %{"type" => "Point", "coordinates" => [51.504232, -0.119175]}
      geohash = Geohash.encode(51.504232, -0.119175, 4)

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      %Task{} =
        task = Web.AreaNotificationChannel.notify(notification, MatchData.new(notification))

      assert_push("notification:broadcast", _payload)

      Task.await(task, 10_000)

      assert %{receivers_count: 1} =
               Repo.get!(BillBored.Notifications.AreaNotification, notification.id)
    end

    test "does not push notification to user outside of radius", %{
      socket: socket,
      notification: notification
    } do
      user_location = %{"type" => "Point", "coordinates" => [51.495599, -0.115269]}
      geohash = Geohash.encode(51.495599, -0.115269, 4)

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      Web.AreaNotificationChannel.notify(notification, MatchData.new(notification))

      refute_push("notification:broadcast", _payload)

      assert %{receivers_count: nil} =
               Repo.get!(BillBored.Notifications.AreaNotification, notification.id)
    end

    test "does not push notification to user not matching filter", %{
      socket: socket,
      owner: owner
    } do
      user_location = %{"type" => "Point", "coordinates" => [51.504232, -0.119175]}
      geohash = Geohash.encode(51.504232, -0.119175, 4)

      {:ok, %{}, %Phoenix.Socket{}} =
        subscribe_and_join(socket, "area_notifications:#{geohash}", %{"geometry" => user_location})

      notification =
        insert(:area_notification,
          location: %BillBored.Geo.Point{lat: 51.5, long: -0.12},
          radius: 500,
          owner: owner,
          sex: "F"
        )
        |> Repo.preload([:owner, :logo, :image])

      Web.AreaNotificationChannel.notify(notification, MatchData.new(notification))

      refute_push("notification:broadcast", _payload)

      assert %{receivers_count: nil} =
               Repo.get!(BillBored.Notifications.AreaNotification, notification.id)
    end
  end
end
