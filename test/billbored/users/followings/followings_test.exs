defmodule BillBored.User.FollowingsTest do
  use BillBored.DataCase, async: true
  alias BillBored.User.Followings.Following
  alias BillBored.User.Followings

  describe "delete_between/2" do
    setup do
      u1 = insert(:user)
      u2 = insert(:user)
      f1 = insert(:user_following, from: u1, to: u2)
      f2 = insert(:user_following, from: u2, to: u1)

      %{u1: u1, u2: u2, f1: f1, f2: f2}
    end

    test "deletes followings between two users", %{u1: u1, u2: u2, f1: f1, f2: f2} do
      assert {2, _} = Followings.delete_between(u1, u2)
      assert nil == Repo.get(Following, f1.id)
      assert nil == Repo.get(Following, f2.id)
    end
  end
end
