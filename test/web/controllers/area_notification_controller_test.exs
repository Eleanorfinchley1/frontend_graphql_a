defmodule Web.AreaNotificationControllerTest do
  use Web.ConnCase, async: true

  import BillBored.ServiceRegistry, only: [replace: 2]

  defmodule Stubs.AreaNotificationChannel do
    def notify(area_notification, match_data) do
      send(self(), {__MODULE__, :notify, {area_notification, match_data}})
      :ok
    end
  end

  setup do
    replace(Web.AreaNotificationChannel, Stubs.AreaNotificationChannel)

    %{business_account: insert(:business_account)}
  end

  describe "create_business_area_notification/2" do
    test "returns error with incomplete params", %{
      conn: conn,
      business_account: business_account
    } do
      assert %{
               "error" => "missing_required_params",
               "reason" =>
                 "Missing required params: image, logo, expires_at, radius, location, title",
               "success" => false
             } ==
               conn
               |> authenticate()
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "message" => "Test notification!"
                 }
               )
               |> json_response(422)
    end

    ["owner", "admin", "member"]
    |> Enum.each(fn role ->
      test "business account #{role} can create area notification", %{
        conn: conn,
        business_account: %{id: business_id} = business_account
      } do
        food = insert(:interest_category, name: "food")
        %{id: post_id} = insert(:business_post, business_account: business_account)

        [%{media_key: image_media_key}, %{media_key: logo_media_key}] = insert_list(2, :upload)

        %{member: user = %{id: owner_id}} =
          insert(:user_membership, role: unquote(role), business_account: business_account)

        assert %{
                 "id" => area_notification_id,
                 "image_url" => "",
                 "location" => %{
                   "coordinates" => [30.0, 76.6],
                   "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                   "type" => "Point"
                 },
                 "logo_url" => "",
                 "message" => "Message",
                 "radius" => 123.456,
                 "title" => "Title",
                 "categories" => ["food"],
                 "sex" => "F",
                 "min_age" => 18,
                 "max_age" => 42,
                 "linked_post_id" => ^post_id
               } =
                 conn
                 |> authenticate(user)
                 |> post(
                   Routes.area_notification_path(
                     conn,
                     :create_business_area_notification,
                     business_account.id
                   ),
                   %{
                     "title" => "Title",
                     "message" => "Message",
                     "location" => [30.0, 76.6],
                     "radius" => 123.456,
                     "expires_at" => "2038-01-01 01:01:01Z",
                     "image" => image_media_key,
                     "logo" => logo_media_key,
                     "categories" => ["food"],
                     "sex" => "F",
                     "min_age" => 18,
                     "max_age" => 42,
                     "linked_post_id" => post_id
                   }
                 )
                 |> json_response(200)

        assert %BillBored.Notifications.AreaNotification{
                 title: "Title",
                 message: "Message",
                 location: %BillBored.Geo.Point{lat: 30.0, long: 76.6},
                 radius: 123.456,
                 logo: %BillBored.Upload{media_key: ^logo_media_key},
                 image: %BillBored.Upload{media_key: ^image_media_key},
                 owner: %{id: ^owner_id},
                 business: %{id: ^business_id},
                 categories: ["food"],
                 sex: "F",
                 min_age: 18,
                 max_age: 42,
                 linked_post_id: ^post_id
               } =
                 Repo.get(BillBored.Notifications.AreaNotification, area_notification_id)
                 |> Repo.preload([:owner, :business, :logo, :image])

        assert_received(
          {Stubs.AreaNotificationChannel, :notify,
           {%BillBored.Notifications.AreaNotification{
              id: ^area_notification_id,
              owner: %{id: ^owner_id},
              business: %{id: ^business_id},
              logo: %{media_key: ^logo_media_key},
              image: %{media_key: ^image_media_key}
            }, match_data}}
        )

        assert %BillBored.Notifications.AreaNotifications.MatchData{
          categories_set: MapSet.new([food.id]),
          max_birthdate: Timex.shift(Timex.today(), [years: -18]),
          min_birthdate: Timex.shift(Timex.today(), [years: -42]),
          sex: "F"
        } == match_data
      end
    end)

    test "creates area notification with empty logo and image", %{
      conn: conn,
      business_account: %{id: business_id} = business_account
    } do
      %{member: user = %{id: owner_id}} =
        insert(:user_membership, role: "member", business_account: business_account)

      assert %{
               "id" => area_notification_id,
               "image_url" => "",
               "location" => %{
                 "coordinates" => [30.0, 76.6],
                 "crs" => %{"properties" => %{"name" => "EPSG:4326"}, "type" => "name"},
                 "type" => "Point"
               },
               "logo_url" => "",
               "message" => "Message",
               "radius" => 123.456,
               "title" => "Title"
             } =
               conn
               |> authenticate(user)
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "",
                   "logo" => ""
                 }
               )
               |> doc()
               |> json_response(200)

      assert %BillBored.Notifications.AreaNotification{
               title: "Title",
               message: "Message",
               location: %BillBored.Geo.Point{lat: 30.0, long: 76.6},
               radius: 123.456,
               logo_media_key: nil,
               image_media_key: nil,
               owner: %{id: ^owner_id},
               business: %{id: ^business_id}
             } =
               Repo.get(BillBored.Notifications.AreaNotification, area_notification_id)
               |> Repo.preload([:owner, :business, :logo, :image])

      assert_received(
        {Stubs.AreaNotificationChannel, :notify,
         {%BillBored.Notifications.AreaNotification{id: ^area_notification_id}, _}}
      )
    end

    test "returns error when linked_post_id is invalid", %{
      conn: conn,
      business_account: business_account
    } do
      %{member: user} =
        insert(:user_membership, role: "member", business_account: business_account)

      auth_token = insert(:auth_token, user: user)

      assert %{"reason" => "invalid_linked_post_id", "success" => false, "error" => "invalid_linked_post_id"} =
               conn
               |> authenticate(auth_token)
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "",
                   "logo" => "",
                   "linked_post_id" => 6666666
                 }
               )
               |> json_response(422)

      refute_received({Stubs.AreaNotificationChannel, :notify, {_, _}})
    end

    test "returns error when linked_post_id refers to another account's post", %{
      conn: conn,
      business_account: business_account
    } do
      %{member: user} =
        insert(:user_membership, role: "member", business_account: business_account)

      %{id: post_id} = insert(:business_post)

      auth_token = insert(:auth_token, user: user)

      assert %{"reason" => "invalid_linked_post_id", "success" => false, "error" => "invalid_linked_post_id"} =
               conn
               |> authenticate(auth_token)
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "",
                   "logo" => "",
                   "linked_post_id" => post_id
                 }
               )
               |> json_response(422)

      refute_received({Stubs.AreaNotificationChannel, :notify, {_, _}})
    end

    test "returns error when image or logo media key is invalid", %{
      conn: conn,
      business_account: business_account
    } do
      %{member: user} =
        insert(:user_membership, role: "member", business_account: business_account)

      auth_token = insert(:auth_token, user: user)

      assert %{"reason" => %{"image_media_key" => ["does not exist"]}, "success" => false} =
               conn
               |> authenticate(auth_token)
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "invalid",
                   "logo" => ""
                 }
               )
               |> doc()
               |> json_response(422)

      assert %{"reason" => %{"logo_media_key" => ["does not exist"]}, "success" => false} =
               conn
               |> authenticate(auth_token)
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "",
                   "logo" => "invalid"
                 }
               )
               |> doc()
               |> json_response(422)

      refute_received({Stubs.AreaNotificationChannel, :notify, {_, _}})
    end

    [
      {"min_age", 10000},
      {"max_age", "abc"},
      {"min_age", -20},
      {"max_age", -3.14},
      {"sex", "unknown"}
    ]
    |> Enum.each(fn {field, value} ->
      test "returns error when #{field} is #{value}", %{
        conn: conn,
        business_account: business_account
      } do
        %{member: user} =
          insert(:user_membership, role: "member", business_account: business_account)

        auth_token = insert(:auth_token, user: user)

        assert %{"reason" => %{unquote(field) => _}, "success" => false} =
                conn
                |> authenticate(auth_token)
                |> post(
                  Routes.area_notification_path(
                    conn,
                    :create_business_area_notification,
                    business_account.id
                  ),
                  %{
                    "title" => "Title",
                    "message" => "Message",
                    "location" => [30.0, 76.6],
                    "radius" => 123.456,
                    "expires_at" => "2038-01-01 01:01:01Z",
                    "image" => "",
                    "logo" => "",
                    unquote(field) => unquote(value)
                  }
                )
                |> json_response(422)

        refute_received({Stubs.AreaNotificationChannel, :notify, {_, _}})
      end
    end)

    test "returns error when categories are invalid", %{
      conn: conn,
      business_account: business_account
    } do
      %{member: user} =
        insert(:user_membership, role: "member", business_account: business_account)

      auth_token = insert(:auth_token, user: user)

      assert %{
              "reason" => "Invalid categories: sports, art",
              "success" => false,
              "error" => "invalid_categories"
             } =
               conn
               |> authenticate(auth_token)
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "",
                   "logo" => "",
                   "categories" => ["sports", "art"]
                 }
               )
               |> doc()
               |> json_response(422)

      assert %{"reason" => %{"logo_media_key" => ["does not exist"]}, "success" => false} =
               conn
               |> authenticate(auth_token)
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "",
                   "logo" => "invalid"
                 }
               )
               |> doc()
               |> json_response(422)

      refute_received({Stubs.AreaNotificationChannel, :notify, {_, _}})
    end

    test "returns error when user is not a member", %{
      conn: conn,
      business_account: business_account
    } do
      assert "" ==
               conn
               |> authenticate()
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   business_account.id
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => "",
                   "logo" => ""
                 }
               )
               |> doc()
               |> response(403)

      refute_received({Stubs.AreaNotificationChannel, :notify, {_, _}})
    end

    test "returns error for invalid business_id", %{conn: conn} do
      assert %{
               "error" => "business_account_not_found",
               "reason" => "business_account_not_found",
               "success" => false
             } ==
               conn
               |> authenticate()
               |> post(
                 Routes.area_notification_path(
                   conn,
                   :create_business_area_notification,
                   66_666_666
                 ),
                 %{
                   "title" => "Title",
                   "message" => "Message",
                   "location" => [30.0, 76.6],
                   "radius" => 123.456,
                   "expires_at" => "2038-01-01 01:01:01Z",
                   "image" => nil,
                   "logo" => nil
                 }
               )
               |> json_response(422)

      refute_received({Stubs.AreaNotificationChannel, :notify, {_, _}})
    end
  end

  describe "delete_business_area_notification/2" do
    setup do
      business_account = insert(:business_account)
      area_notification = insert(:area_notification, business_id: business_account.id)

      %{business_account: business_account, area_notification: area_notification}
    end

    ["owner", "admin"]
    |> Enum.each(fn role ->
      test "deletes area notification when user is a business account #{role}", %{
        conn: conn,
        business_account: business_account,
        area_notification: area_notification
      } do
        %{member: user} =
          insert(:user_membership, role: unquote(role), business_account: business_account)

        assert "" ==
                 conn
                 |> authenticate(user)
                 |> delete(
                   Routes.area_notification_path(
                     conn,
                     :delete_business_area_notification,
                     business_account.id,
                     area_notification.id
                   )
                 )
                 |> doc()
                 |> response(204)

        assert nil == Repo.get(BillBored.Notifications.AreaNotification, area_notification.id)
      end
    end)

    test "returns error when user is a member of the business account but not the notification's owner",
         %{
           conn: conn,
           business_account: business_account,
           area_notification: area_notification
         } do
      %{member: user} =
        insert(:user_membership, role: "member", business_account: business_account)

      assert "" ==
               conn
               |> authenticate(user)
               |> delete(
                 Routes.area_notification_path(
                   conn,
                   :delete_business_area_notification,
                   business_account.id,
                   area_notification.id
                 )
               )
               |> doc()
               |> response(403)

      assert %BillBored.Notifications.AreaNotification{} =
               Repo.get(BillBored.Notifications.AreaNotification, area_notification.id)
    end

    test "returns error when user is not related to the business account", %{
      conn: conn,
      business_account: business_account,
      area_notification: area_notification
    } do
      assert "" ==
               conn
               |> authenticate()
               |> delete(
                 Routes.area_notification_path(
                   conn,
                   :delete_business_area_notification,
                   business_account.id,
                   area_notification.id
                 )
               )
               |> response(403)

      assert %BillBored.Notifications.AreaNotification{} =
               Repo.get(BillBored.Notifications.AreaNotification, area_notification.id)
    end
  end

  describe "list_business_area_notifications/2" do
    setup do
      business_account = insert(:business_account)

      an1 = insert(:area_notification, business_id: business_account.id)
      an2 = insert(:area_notification, business_id: business_account.id)

      image =
        insert(:upload,
          media_type: "image",
          media: %{file_name: "http://example.com/image.png", updated_at: DateTime.utc_now()}
        )

      logo =
        insert(:upload,
          media_type: "image",
          media: %{file_name: "http://example.com/logo.png", updated_at: DateTime.utc_now()}
        )

      an3 =
        insert(:area_notification,
          business_id: business_account.id,
          inserted_at: ~U[2038-12-30 12:12:12Z],
          expires_at: ~U[2038-12-31 23:59:59.999999Z],
          image: image,
          logo: logo
        )

      _ignored = insert(:area_notification)

      image_url = BillBored.Uploads.File.url({image.media, image}, :original)
      logo_url = BillBored.Uploads.File.url({logo.media, logo}, :original)

      %{
        business_account: business_account,
        area_notifications: [an1, an2, an3],
        image_url: image_url,
        logo_url: logo_url
      }
    end

    ["owner", "admin", "member"]
    |> Enum.each(fn role ->
      test "returns first page when user is a business account #{role}", %{
        conn: conn,
        business_account: %{id: business_id} = business_account,
        area_notifications: [%{id: an1_id}, %{id: an2_id}, %{id: an3_id}],
        image_url: image_url,
        logo_url: logo_url
      } do
        %{member: user} =
          insert(:user_membership, role: unquote(role), business_account: business_account)

        assert %{
                 "page" => 1,
                 "page_size" => 30,
                 "entries" => [
                   %{
                     "id" => ^an3_id,
                     "business" => %{"id" => ^business_id},
                     "owner" => %{"id" => _},
                     "image_url" => ^image_url,
                     "logo_url" => ^logo_url,
                     "inserted_at" => "2038-12-30T12:12:12.000000Z",
                     "expires_at" => "2038-12-31T23:59:59.999999Z"
                   },
                   %{
                     "id" => ^an2_id,
                     "business" => %{"id" => ^business_id},
                     "owner" => %{"id" => _}
                   },
                   %{
                     "id" => ^an1_id,
                     "business" => %{"id" => ^business_id},
                     "owner" => %{"id" => _}
                   }
                 ]
               } =
                 conn
                 |> authenticate(user)
                 |> get(
                   Routes.area_notification_path(
                     conn,
                     :list_business_area_notifications,
                     business_account.id
                   )
                 )
                 |> json_response(200)
      end
    end)

    test "returns pages of page_size items", %{
      conn: conn,
      business_account: business_account,
      area_notifications: [%{id: an1_id}, %{id: an2_id}, %{id: an3_id}]
    } do
      %{member: user} =
        insert(:user_membership, role: "member", business_account: business_account)

      auth_token = insert(:auth_token, user: user)

      assert %{
               "page" => 1,
               "page_size" => 1,
               "entries" => [%{"id" => ^an3_id}]
             } =
               conn
               |> authenticate(auth_token)
               |> get(
                 Routes.area_notification_path(
                   conn,
                   :list_business_area_notifications,
                   business_account.id
                 ),
                 %{"page_size" => 1}
               )
               |> json_response(200)

      assert %{
               "page" => 2,
               "page_size" => 1,
               "entries" => [%{"id" => ^an2_id}]
             } =
               conn
               |> authenticate(auth_token)
               |> get(
                 Routes.area_notification_path(
                   conn,
                   :list_business_area_notifications,
                   business_account.id
                 ),
                 %{"page_size" => 1, "page" => 2}
               )
               |> doc()
               |> json_response(200)

      assert %{
               "page" => 3,
               "page_size" => 1,
               "entries" => [%{"id" => ^an1_id}]
             } =
               conn
               |> authenticate(auth_token)
               |> get(
                 Routes.area_notification_path(
                   conn,
                   :list_business_area_notifications,
                   business_account.id
                 ),
                 %{"page_size" => 1, "page" => 3}
               )
               |> json_response(200)

      assert %{
               "page" => 4,
               "page_size" => 1,
               "entries" => []
             } =
               conn
               |> authenticate(auth_token)
               |> get(
                 Routes.area_notification_path(
                   conn,
                   :list_business_area_notifications,
                   business_account.id
                 ),
                 %{"page_size" => 1, "page" => 4}
               )
               |> json_response(200)
    end

    test "returns error when user is not related to business account", %{
      conn: conn,
      business_account: business_account
    } do
      assert "" =
               conn
               |> authenticate()
               |> get(
                 Routes.area_notification_path(
                   conn,
                   :list_business_area_notifications,
                   business_account.id
                 )
               )
               |> response(403)
    end
  end
end
