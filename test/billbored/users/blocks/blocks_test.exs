defmodule BillBored.User.BlocksTest do
  use BillBored.DataCase, async: true
  import Ecto.Query
  alias BillBored.User.{Block, Blocks}

  describe "block/2" do
    setup do
      user = insert(:user)
      another_user = insert(:user)

      %{user: user, another_user: another_user}
    end

    test "creates a new block", %{user: blocker_user, another_user: blocked_user} do
      {:ok, block} = Blocks.block(blocker_user, blocked_user)
      assert blocker_user == block.blocker
      assert blocked_user == block.blocked

      assert 1 ==
               Repo.aggregate(
                 from(b in Block, where: b.to_userprofile_id == ^blocker_user.id),
                 :count,
                 :id
               )
    end

    test "removes blocked user following", %{user: blocker_user, another_user: blocked_user} do
      insert(:user_following, from: blocked_user, to: blocker_user)
      another_following = insert(:user_following, from: blocked_user)

      {:ok, _block} = Blocks.block(blocker_user, blocked_user)
      assert %Scrivener.Page{total_entries: 0} = BillBored.User.Followings.index_followers(blocker_user.id, %{})
      assert %Scrivener.Page{total_entries: 1} = BillBored.User.Followings.index_followers(another_following.to.id, %{})
    end

    test "removes blocker user following", %{user: blocker_user, another_user: blocked_user} do
      insert(:user_following, from: blocker_user, to: blocked_user)
      another_following = insert(:user_following, from: blocker_user)

      {:ok, _block} = Blocks.block(blocker_user, blocked_user)
      assert %Scrivener.Page{total_entries: 0} = BillBored.User.Followings.index_followers(blocker_user.id, %{})
      assert %Scrivener.Page{total_entries: 1} = BillBored.User.Followings.index_followers(another_following.to.id, %{})
    end
  end

  describe "get_blocked_by/1" do
    setup do
      blocker = insert(:user)
      blocks = insert_list(3, :user_block, blocker: blocker)
      blocks = blocks |> Enum.sort_by(& &1.blocked.id)

      %{blocker: blocker, blocks: blocks}
    end

    test "returns blocked users for user", %{blocker: blocker, blocks: blocks} do
      assert blocks |> Enum.map(& &1.blocked.id) ==
               Blocks.get_blocked_by(blocker) |> Enum.map(& &1.id) |> Enum.sort()
    end
  end

  describe "get_blockers_of/1" do
    setup do
      blocked = insert(:user)
      blocks = insert_list(3, :user_block, blocked: blocked)
      blocks = blocks |> Enum.sort_by(& &1.blocker.id)

      %{blocked: blocked, blocks: blocks}
    end

    test "returns blockers of user", %{blocked: blocked, blocks: blocks} do
      assert blocks |> Enum.map(& &1.blocker.id) ==
               Blocks.get_blockers_of(blocked) |> Enum.map(& &1.id) |> Enum.sort()
    end
  end
end
