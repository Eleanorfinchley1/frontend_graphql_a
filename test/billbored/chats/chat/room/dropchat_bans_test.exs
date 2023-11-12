defmodule BillBored.Chat.Room.DropchatBansTest do
  use BillBored.DataCase, async: true

  alias BillBored.User
  alias BillBored.Chat.Room
  alias BillBored.Chat.Room.DropchatBan
  alias BillBored.Chat.Room.DropchatBans

  setup do
    dropchat = insert(:chat_room, chat_type: "dropchat")
    admin = insert(:chat_room_administratorship, room: dropchat).user
    user = insert(:user)

    %{dropchat: dropchat, admin: admin, user: user}
  end

  describe "create/3" do
    test "creates ban", %{dropchat: dropchat, admin: admin, user: user} do
      Phoenix.PubSub.subscribe(Web.PubSub, "user:#{user.id}:dropchat")
      assert {:ok, _} = DropchatBans.create(dropchat, admin, user)

      assert from(b in DropchatBan,
        where: b.dropchat_id == ^dropchat.id and
               b.admin_id == ^admin.id and
               b.banned_user_id == ^user.id
      ) |> Repo.exists?()

      assert_receive {:dropchat_ban, %{user: %User{id: user_id}, room: %Room{id: room_id}}}
      assert user_id == user.id
      assert room_id == dropchat.id
    end

    test "creates ban when user doesn't have administratorship", %{
      dropchat: dropchat,
      user: user
    } do
      another_user = insert(:user)
      assert {:ok, _} = DropchatBans.create(dropchat, another_user, user)

      assert from(b in DropchatBan,
        where: b.dropchat_id == ^dropchat.id and
               b.admin_id == ^another_user.id and
               b.banned_user_id == ^user.id
      ) |> Repo.exists?()
    end

    test "does not create additional ban when user is already banned", %{dropchat: dropchat, admin: admin, user: user} do
      assert {:ok, _} = DropchatBans.create(dropchat, admin, user)
      assert {:ok, _} = DropchatBans.create(dropchat, insert(:user), user)

      assert 1 == from(b in DropchatBan,
        select: count(b),
        where: b.dropchat_id == ^dropchat.id and
               b.admin_id == ^admin.id and
               b.banned_user_id == ^user.id
      ) |> Repo.one()
    end
  end
end