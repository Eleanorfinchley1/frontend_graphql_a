defmodule BillBored.Chat.MessagesTest do
  use BillBored.DataCase, async: true
  alias BillBored.{Chat, User, Interest, Hashtag}

  setup do
    room = insert(:chat_room)
    user = insert(:user)

    _membership = insert(:chat_room_membership, room: room, user: user)

    %{room: room, user: user}
  end

  describe "create" do
    test "basic", %{room: %Chat.Room{id: room_id}, user: %User{id: user_id}} do
      attrs = %{
        message: "hello",
        message_type: "TXT"
      }

      {:ok, %Chat.Message{} = message} =
        Chat.Messages.create(attrs, room_id: room_id, user_id: user_id)

      assert message.message == "hello"
      assert message.message_type == "TXT"
    end

    test "with private post", %{room: %Chat.Room{id: room_id}, user: %User{id: user_id} = user} do
      private_post = insert(:post, body: "great", author: user)

      attrs = %{
        message: "hello there",
        message_type: "PST",
        private_post_id: private_post.id
      }

      {:ok, %Chat.Message{} = message} =
        Chat.Messages.create(attrs, room_id: room_id, user_id: user_id)

      assert message.message == "hello there"
      assert message.message_type == "PST"
      assert message.private_post_id == private_post.id
    end

    test "with interest hashtags", %{room: %Chat.Room{id: room_id}, user: %User{id: user_id}} do
      %Interest{} = food = insert(:interest, hashtag: "Food")
      %Interest{} = fashion = insert(:interest, hashtag: "Fashion")

      attrs = %{
        "message" => "hello #Food #Fashion",
        "message_type" => "TXT",
        "hashtags" => ["Food", "Fashion"]
      }

      {:ok, %Chat.Message{} = message} =
        Chat.Messages.create(attrs, room_id: room_id, user_id: user_id)

      assert message.message == "hello #Food #Fashion"
      assert message.message_type == "TXT"

      # verify that the interest <-> message relationship has been saved
      assert Repo.get_by(Chat.Message.Interest, message_id: message.id, interest_id: food.id)
      assert Repo.get_by(Chat.Message.Interest, message_id: message.id, interest_id: fashion.id)
    end

    test "with existing custom hashtags", %{
      room: %Chat.Room{id: room_id},
      user: %User{id: user_id}
    } do
      %Hashtag{} = test1 = insert(:hashtag, value: "test1")
      %Hashtag{} = test2 = insert(:hashtag, value: "test2")

      attrs = %{
        "message" => "hello #test1 #test2",
        "message_type" => "TXT",
        "hashtags" => ["test1", "test2"]
      }

      {:ok, %Chat.Message{} = message} =
        Chat.Messages.create(attrs, room_id: room_id, user_id: user_id)

      assert message.message == "hello #test1 #test2"
      assert message.message_type == "TXT"

      # verify that the custom hashtag <-> message relationship has been saved
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test1.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test2.id)
    end

    test "with new custom hashtags", %{room: %Chat.Room{id: room_id}, user: %User{id: user_id}} do
      attrs = %{
        "message" => "hello #test1 #test2",
        "message_type" => "TXT",
        "hashtags" => ["test1", "test2"]
      }

      {:ok, %Chat.Message{} = message} =
        Chat.Messages.create(attrs, room_id: room_id, user_id: user_id)

      assert message.message == "hello #test1 #test2"
      assert message.message_type == "TXT"

      test1 = Repo.get_by(Hashtag, value: "test1")
      test2 = Repo.get_by(Hashtag, value: "test2")

      # verify that the custom hashtag <-> message relationship has been saved
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test1.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test2.id)
    end

    test "with both new and existing custom hashtags", %{
      room: %Chat.Room{id: room_id},
      user: %User{id: user_id}
    } do
      %Hashtag{} = test1 = insert(:hashtag, value: "test1")
      %Hashtag{} = test2 = insert(:hashtag, value: "test2")

      attrs = %{
        "message" => "hello #test1 #test2 #test3 #test4",
        "message_type" => "TXT",
        "hashtags" => ["test1", "test2", "test3", "test4"]
      }

      {:ok, %Chat.Message{} = message} =
        Chat.Messages.create(attrs, room_id: room_id, user_id: user_id)

      assert message.message == "hello #test1 #test2 #test3 #test4"
      assert message.message_type == "TXT"

      test3 = Repo.get_by(Hashtag, value: "test3")
      test4 = Repo.get_by(Hashtag, value: "test4")

      # verify that the custom hashtag <-> message relationship has been saved
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test1.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test2.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test3.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test4.id)
    end

    test "with both interest and custom hashtags", %{
      room: %Chat.Room{id: room_id},
      user: %User{id: user_id}
    } do
      %Interest{} = food = insert(:interest, hashtag: "Food")
      %Interest{} = fashion = insert(:interest, hashtag: "Fashion")
      %Hashtag{} = test1 = insert(:hashtag, value: "test1")
      %Hashtag{} = test2 = insert(:hashtag, value: "test2")

      attrs = %{
        "message" => "hello #test1 #Food #test2 #Fashion #test3 #test4",
        "message_type" => "TXT",
        "hashtags" => ["test1", "Food", "test2", "Fashion", "test3", "test4"]
      }

      {:ok, %Chat.Message{} = message} =
        Chat.Messages.create(attrs, room_id: room_id, user_id: user_id)

      assert message.message == "hello #test1 #Food #test2 #Fashion #test3 #test4"
      assert message.message_type == "TXT"

      test3 = Repo.get_by(Hashtag, value: "test3")
      test4 = Repo.get_by(Hashtag, value: "test4")

      # verify that the custom hashtag <-> message relationship has been saved
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test1.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test2.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test3.id)
      assert Repo.get_by(Chat.Message.Hashtag, message_id: message.id, hashtag_id: test4.id)

      # verify that the interest <-> message relationship has been saved
      assert Repo.get_by(Chat.Message.Interest, message_id: message.id, interest_id: food.id)
      assert Repo.get_by(Chat.Message.Interest, message_id: message.id, interest_id: fashion.id)
    end

    test "too long", %{user: user, room: room} do
      attrs = %{
        "message" => String.duplicate("A", 3001),
        "message_type" => "TXT"
      }

      assert {:error, %Ecto.Changeset{valid?: false} = changeset} =
               Chat.Messages.create(attrs, room_id: room.id, user_id: user.id)

      assert errors_on(changeset) == %{message: ["should be at most 3000 character(s)"]}
    end
  end
end
