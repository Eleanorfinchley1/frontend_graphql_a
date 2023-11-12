defmodule BillBored.Chat.RoomsTest do
  use BillBored.DataCase, async: true
  alias BillBored.{Chat, User}

  setup do
    %{user: insert(:user)}
  end

  describe "create/3" do
    test "creates chat", %{user: %User{id: admin_user_id}} do
      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "dropchat",
        fake_location?: false
      }

      assert {:ok, room} = Chat.Rooms.create(admin_user_id, attrs)

      room = Repo.preload(room, [:participants, :administrators])
      assert [%{id: ^admin_user_id}] = room.administrators

      assert 1 == Enum.count(room.participants)
      assert %{userprofile_id: ^admin_user_id, role: "administrator"} = Chat.Room.Memberships.get_by(user_id: admin_user_id, room_id: room.id)
    end

    test "adds members set by :add_members option", %{user: %User{id: admin_user_id}} do
      member_ids = [m1_id, m2_id] = insert_list(2, :user) |> Enum.map(& &1.id)

      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "dropchat",
        fake_location?: false
      }

      assert {:ok, room} = Chat.Rooms.create(admin_user_id, attrs, add_members: member_ids)

      room = Repo.preload(room, [:participants, :administrators])
      assert [%{id: ^admin_user_id}] = room.administrators

      assert 3 == Enum.count(room.participants)
      assert %{userprofile_id: ^admin_user_id, role: "administrator"} = Chat.Room.Memberships.get_by(user_id: admin_user_id, room_id: room.id)
      assert %{userprofile_id: ^m1_id, role: "member"} = Chat.Room.Memberships.get_by(user_id: m1_id, room_id: room.id)
      assert %{userprofile_id: ^m2_id, role: "member"} = Chat.Room.Memberships.get_by(user_id: m2_id, room_id: room.id)
    end

    test "correctly adds administrator when he is included in :add_members option", %{user: %User{id: admin_user_id}} do
      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "dropchat",
        fake_location?: false
      }

      assert {:ok, room} = Chat.Rooms.create(admin_user_id, attrs, add_members: [admin_user_id])

      room = Repo.preload(room, [:participants, :administrators])
      assert [%{id: ^admin_user_id}] = room.administrators

      assert 1 == Enum.count(room.participants)
      assert %{userprofile_id: ^admin_user_id, role: "administrator"} = Chat.Room.Memberships.get_by(user_id: admin_user_id, room_id: room.id)
    end

    test "correctly adds members when the same user listed multiple times in :add_members option", %{user: %User{id: admin_user_id}} do
      member = %{id: member_id} = insert(:user)

      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "dropchat",
        fake_location?: false
      }

      assert {:ok, room} = Chat.Rooms.create(admin_user_id, attrs, add_members: [member.id, member.id, member.id])

      room = Repo.preload(room, [:participants, :administrators])
      assert [%{id: ^admin_user_id}] = room.administrators

      assert 2 == Enum.count(room.participants)
      assert %{userprofile_id: ^admin_user_id, role: "administrator"} = Chat.Room.Memberships.get_by(user_id: admin_user_id, room_id: room.id)
      assert %{userprofile_id: ^member_id, role: "member"} = Chat.Room.Memberships.get_by(user_id: member.id, room_id: room.id)
    end

    test "creates one-to-one chat", %{user: %User{id: admin_user_id}} do
      member = %{id: member_id} = insert(:user)

      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "one-to-one",
        fake_location?: false
      }

      assert {:ok, room} = Chat.Rooms.create(admin_user_id, attrs, add_members: [member.id])

      room = Repo.preload(room, [:participants, :administrators])
      assert [%{id: ^admin_user_id}] = room.administrators

      assert 2 == Enum.count(room.participants)
      # SIC! one-to-one chats don't have administrators, users are equal members
      assert %{userprofile_id: ^admin_user_id, role: "member"} = Chat.Room.Memberships.get_by(user_id: admin_user_id, room_id: room.id)
      assert %{userprofile_id: ^member_id, role: "member"} = Chat.Room.Memberships.get_by(user_id: member.id, room_id: room.id)
    end

    test "does not create one-to-one chat without second member", %{user: %User{id: admin_user_id}} do
      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "one-to-one",
        fake_location?: false
      }

      assert {:error, :validate_members, :must_have_two_members, %{}} =
        Chat.Rooms.create(admin_user_id, attrs)
    end

    test "does not create one-to-one chat with more than two members", %{user: %User{id: admin_user_id}} do
      member_ids = insert_list(2, :user) |> Enum.map(& &1.id)

      attrs = %{
        location: %BillBored.Geo.Point{lat: 30.7008, long: 76.7885},
        color: "#FF006D",
        reach_area_radius: Decimal.new(20),
        last_interaction: DateTime.utc_now(),
        title: "Chat title",
        chat_type: "one-to-one",
        fake_location?: false
      }

      assert {:error, :validate_members, :must_have_two_members, %{}} =
        Chat.Rooms.create(admin_user_id, attrs, add_members: member_ids)
    end
  end

  test "list", %{user: %User{} = user} do
    # creates rooms where our user is a member
    %Chat.Room.Membership{room: room1} = insert(:chat_room_membership, user: user)
    %Chat.Room.Membership{room: room2} = insert(:chat_room_membership, user: user)
    %Chat.Room.Membership{room: room3} = insert(:chat_room_membership, user: user)
    %Chat.Room.Membership{room: room4} = insert(:chat_room_membership, user: user)

    # creates other user (TODO create more than one)
    other_user = insert(:user)
    insert(:chat_room_membership, user: other_user, room: room1)
    insert(:chat_room_membership, user: other_user, room: room2)
    insert(:chat_room_membership, user: other_user, room: room3)

    # creates messages in these rooms
    %Chat.Message{} = insert(:chat_message, user: user, room: room1, message: "Hi")
    %Chat.Message{} = insert(:chat_message, user: other_user, room: room1, message: "Hey")

    %Chat.Message{} = insert(:chat_message, user: other_user, room: room2, message: "Haha")
    %Chat.Message{} = insert(:chat_message, user: user, room: room2, message: "yeah right")

    %Chat.Message{} = insert(:chat_message, user: user, room: room3, message: "oh damn")
    %Chat.Message{} = insert(:chat_message, user: other_user, room: room3, message: "i told ya")

    fetched_rooms = Chat.Rooms.list(for: user)

    fetched_room_ids = Enum.map(fetched_rooms, fn %Chat.Room{id: room_id} -> room_id end)

    # asserts all rooms have been fetched
    assert room1.id in fetched_room_ids
    assert room2.id in fetched_room_ids
    assert room3.id in fetched_room_ids
    assert room4.id in fetched_room_ids

    # asserts last messages are correct (TODO rooms are sorted by last activity)
    refute Enum.at(fetched_rooms, 0).last_message
    assert Enum.at(fetched_rooms, 1).last_message.message == "i told ya"
    assert Enum.at(fetched_rooms, 2).last_message.message == "yeah right"
    assert Enum.at(fetched_rooms, 3).last_message.message == "Hey"

    fetched_members =
      fetched_rooms
      |> Enum.group_by(fn %Chat.Room{id: room_id} -> room_id end, fn %Chat.Room{members: members} ->
        Enum.map(members, fn %User{id: user_id} -> user_id end)
      end)
      |> Enum.map(fn {room_id, [members]} -> {room_id, members} end)
      |> Enum.into(%{})

    # TODO asserts the members have been loaded
    assert user.id in fetched_members[room1.id]
    assert user.id in fetched_members[room2.id]
    assert user.id in fetched_members[room3.id]
    assert other_user.id in fetched_members[room1.id]
    assert other_user.id in fetched_members[room2.id]
    assert other_user.id in fetched_members[room3.id]
  end

  test "list_dropchats returns messages count" do
    location = %BillBored.Geo.Point{lat: 40.5, long: -50.0}

    %Chat.Room{} =
      dropchat1 = insert(:chat_room, chat_type: "dropchat", location: location, private: false)

    insert(:chat_message, room: dropchat1, message: "oh damn")
    insert(:chat_message, room: dropchat1, message: "oh damn2")

    %Chat.Room{} =
      dropchat2 = insert(:chat_room, chat_type: "dropchat", location: location, private: false)

    insert(:chat_message, room: dropchat2, message: "oh damn")
    insert(:chat_message, room: dropchat2, message: "oh damn2")
    insert(:chat_message, room: dropchat2, message: "oh damn3")

    assert [fetched_dropchat1, fetched_dropchat2] =
             location
             |> Chat.Rooms.list_dropchats_by_location(1000)
             |> Enum.sort_by(fn dropchat -> dropchat.id end)

    assert fetched_dropchat1.messages_count == 2
    assert fetched_dropchat2.messages_count == 3
  end

  describe "admin?/2" do
    setup [:create_user, :create_room]

    test "when is admin", %{room: room, user: user} do
      insert(:chat_room_administratorship, room: room, user: user)
      assert Chat.Rooms.admin?(room, user)
    end

    test "whan isn't admin", %{room: room, user: user} do
      refute Chat.Rooms.admin?(room, user)
    end
  end

  describe "priveleged_member?/2" do
    setup [:create_user, :create_room]

    test "when is admin", %{room: room, user: user} do
      insert(:chat_room_administratorship, room: room, user: user)
      assert Chat.Rooms.priveleged_member?(room, user)
    end

    test "when has elevated privelege", %{room: room, user: user} do
      insert(:chat_room_elevated_privilege, dropchat: room, user: user)
      assert Chat.Rooms.priveleged_member?(room, user)
    end

    test "when isn't priveleged", %{room: room, user: user} do
      refute Chat.Rooms.priveleged_member?(room, user)
    end
  end

  describe "get_dropchat_statistics/1" do
    test "works with integer ids" do
      location = %BillBored.Geo.Point{lat: 40.5, long: -50.0}

      %Chat.Room{} =
        dropchat1 = insert(:chat_room, chat_type: "dropchat", location: location, private: false)

      %Chat.Room{} =
        dropchat2 = insert(:chat_room, chat_type: "dropchat", location: location, private: false)

      # to verify that we don't return message counts for dropchats whose ids are not in `dropchat_ids`
      %Chat.Room{} =
        dropchat3 = insert(:chat_room, chat_type: "dropchat", location: location, private: false)

      # insert some messages

      insert(:chat_message, room: dropchat2, message: "oh damn")
      insert(:chat_message, room: dropchat2, message: "oh damn2")
      insert(:chat_message, room: dropchat2, message: "oh damn3")

      insert(:chat_message, room: dropchat1, message: "oh damn")
      insert(:chat_message, room: dropchat1, message: "oh damn2")

      insert(:chat_message, room: dropchat3, message: "oh damn")

      dropchat_ids = [dropchat2.id, dropchat1.id]

      fetched_statistics =
        dropchat_ids
        |> Chat.Rooms.get_dropchat_statistics()
        |> Enum.sort_by(fn %{id: id} -> id end)

      assert fetched_statistics ==
               [
                 %{id: dropchat1.id, messages_count: 2},
                 %{id: dropchat2.id, messages_count: 3}
               ]
    end
  end

  describe "get_dropchats/4" do
    setup do
      location = %BillBored.Geo.Point{lat: 40.5, long: -50.0}
      dropchat = insert(:chat_room, chat_type: "dropchat", location: location, private: false)
      insert(:chat_room, chat_type: "dropchat", location: location, private: true)
      user = insert(:user)

      %{location: location, dropchat: dropchat, user: user}
    end

    test "returns public dropchats", %{dropchat: %{id: dropchat_id}, user: user} do
      assert [%Chat.Room{id: ^dropchat_id}] = Chat.Rooms.get_dropchats(user.id, nil, 10, 0)
    end

    test "does not return dropchats the user is banned from", %{dropchat: dropchat, user: user} do
      insert(:dropchat_ban, dropchat: dropchat, banned_user: user)
      assert [] == Chat.Rooms.get_dropchats(user.id, nil, 10, 0)
    end
  end

  describe "get_all_dropchats/4" do
    setup do
      location = %BillBored.Geo.Point{lat: 40.5, long: -50.0}
      chat1 = insert(:chat_room, chat_type: "dropchat", location: location, private: false)
      chat2 = insert(:chat_room, chat_type: "dropchat", location: location, private: false, created: ~U[2022-01-01 00:00:00Z])
      insert(:chat_room, chat_type: "dropchat", location: location, private: true)
      user = insert(:user)

      %{location: location, dropchats: [chat1, chat2], user: user}
    end

    test "returns public dropchats", %{dropchats: [%{id: chat1_id}, %{id: chat2_id}], user: user} do
      assert [
        %Chat.Room{id: ^chat1_id},
        %Chat.Room{id: ^chat2_id}
      ] = Chat.Rooms.get_all_dropchats(user.id, 0, 10)

      assert [
        %Chat.Room{id: ^chat2_id}
      ] = Chat.Rooms.get_all_dropchats(user.id, 2, 1)
    end

    test "does not return dropchats the user is banned from", %{dropchats: [chat1, %{id: chat2_id}], user: user} do
      insert(:dropchat_ban, dropchat: chat1, banned_user: user)

      assert [
        %Chat.Room{id: ^chat2_id}
      ] = Chat.Rooms.get_all_dropchats(user.id, 1, 1)
    end

    test "returns dropchats with active stream first", %{user: user} do
      location = %BillBored.Geo.Point{lat: 40.5, long: -50.0}
      chat1 = %{id: chat1_id} = insert(:chat_room, chat_type: "dropchat", location: location, private: false, created: ~U[2022-05-01 00:00:00Z])
      chat2 = %{id: chat2_id} = insert(:chat_room, chat_type: "dropchat", location: location, private: false, created: ~U[2022-01-01 00:00:00Z])
      chat3 = insert(:chat_room, chat_type: "dropchat", location: location, private: false, created: ~U[2022-11-01 00:00:00Z])
      insert(:dropchat_stream, dropchat: chat1, last_audience_count: 2)
      insert(:dropchat_stream, dropchat: chat2, last_audience_count: 14)
      insert(:dropchat_stream, dropchat: chat3, last_audience_count: 100, status: "finished")

      assert [
        %Chat.Room{id: ^chat2_id},
        %Chat.Room{id: ^chat1_id}
      ] = Chat.Rooms.get_all_dropchats(user.id, 1, 2)
    end
  end

  def create_room(_context) do
    {:ok, %{room: insert(:chat_room)}}
  end

  def create_user(_context) do
    {:ok, %{room: insert(:user)}}
  end
end
