defmodule Web.DropchatViewTest do
  use Web.ConnCase, async: true
  alias BillBored.Chat

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  describe "dropchat.json" do
    test "with place" do
      place = insert(:place, location: %BillBored.Geo.Point{lat: 40.5, long: -50.0})
      place = %{place | types: []}

      %Chat.Room{
        id: id,
        key: key,
        created: created
      } =
        dropchat =
        insert(
          :chat_room,
          private: false,
          title: "wow",
          chat_type: "dropchat",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          color: "coffee",
          place: place,
          reach_area_radius: 2.0
        )

      dropchat = %{
        dropchat
        | messages_count: 123,
          is_access_required: false
      }

      %{userprofile_id: admin_id} = insert(:chat_room_administratorship, room: dropchat)
      %{userprofile_id: member_id} = insert(:chat_room_membership, room: dropchat, role: "member")

      %{userprofile_id: moderator_id} =
        insert(:chat_room_membership, room: dropchat, role: "moderator")

      dropchat = Repo.preload(dropchat, [:members, :moderators, :administrators])

      rendered_dropchat = render(Web.RoomView, "dropchat.json", room: dropchat)

      assert Map.drop(rendered_dropchat, ["users", "moderators", "administrators"]) == %{
               "id" => id,
               "key" => key,
               "title" => "wow",
               "created" => created,
               "chat_type" => "dropchat",
               "private" => false,
               "last_message" => nil,
               "reactions_count" => nil,
               "location" => %{
                 coordinates: [40.5, -50.0],
                 crs: %{
                   properties: %{name: "EPSG:4326"},
                   type: "name"
                 },
                 type: "Point"
               },
               "messages_count" => 123,
               "color" => "coffee",
               "place" => %{
                 name: place.name,
                 vicinity: place.vicinity,
                 address: place.address,
                 icon: place.icon,
                 location: %{
                   coordinates: [40.5, -50.0],
                   crs: %{
                     properties: %{name: "EPSG:4326"},
                     type: "name"
                   },
                   type: "Point"
                 },
                 place_id: place.place_id,
                 types: []
               },
               "is_access_required" => false,
               "active_stream" => nil,
               "ghost_allowed" => true
             }

      assert [%{id: ^member_id}] = rendered_dropchat["users"]
      assert [%{id: ^moderator_id}] = rendered_dropchat["moderators"]
      assert [%{id: ^admin_id}] = rendered_dropchat["administrators"]
    end

    test "without place" do
      %Chat.Room{
        id: id,
        key: key,
        created: created
      } =
        dropchat =
        insert(
          :chat_room,
          private: false,
          title: "wow",
          chat_type: "drop",
          location: %BillBored.Geo.Point{lat: 40.5, long: -50.0},
          color: "coffee"
        )

      dropchat = %{dropchat | messages_count: 123, place: nil, is_access_required: true}

      assert render(Web.RoomView, "dropchat.json", room: dropchat) == %{
               "id" => id,
               "key" => key,
               "title" => "wow",
               "created" => created,
               "chat_type" => "drop",
               "private" => false,
               "last_message" => nil,
               "reactions_count" => nil,
               "location" => %{
                 coordinates: [40.5, -50.0],
                 crs: %{
                   properties: %{name: "EPSG:4326"},
                   type: "name"
                 },
                 type: "Point"
               },
               "messages_count" => 123,
               "color" => "coffee",
               "place" => nil,
               "is_access_required" => true,
               "users" => nil,
               "moderators" => nil,
               "administrators" => nil,
               "active_stream" => nil,
               "ghost_allowed" => true
             }
    end
  end
end
