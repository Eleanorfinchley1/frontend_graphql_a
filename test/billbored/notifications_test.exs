defmodule BillBored.NotificationsTest do
  use BillBored.DataCase, async: true
  alias BillBored.{Notifications, User}

  describe "unread_count/1" do
    setup do
      {:ok, user: insert(:user)}
    end

    test "without notifications", %{user: user} do
      assert 0 == Notifications.unread_count(user.id)
    end

    test "with notifications", %{user: user} do
      insert_list(3, :notification, recipient: user)
      assert 3 == Notifications.unread_count(user.id)
    end

    test "doesn't count read notifications", %{user: user} do
      insert_list(3, :notification, recipient: user, unread: false)
      assert 0 == Notifications.unread_count(user.id)
    end
  end

  describe "unread_counts/1" do
    setup do
      {:ok, users: insert_list(3, :user)}
    end

    defp user_ids(users) do
      Enum.map(users, & &1.id)
    end

    test "without notifications", %{users: users} do
      assert %{} = unread_counts = Notifications.unread_counts(user_ids(users))
      assert map_size(unread_counts) == 0
    end

    test "with notifications", %{users: [u1, u2, u3] = users} do
      users
      |> Enum.with_index(1)
      |> Enum.each(fn {user, idx} -> insert_list(idx, :notification, recipient: user) end)

      assert %{} = unread_counts = Notifications.unread_counts(user_ids(users))
      assert map_size(unread_counts) == 3
      assert unread_counts[u1.id] == 1
      assert unread_counts[u2.id] == 2
      assert unread_counts[u3.id] == 3
    end

    test "doesn't count read notifications", %{users: users} do
      users
      |> Enum.with_index(1)
      |> Enum.each(fn {user, idx} ->
        insert_list(idx, :notification, recipient: user, unread: false)
      end)

      assert %{} = unread_counts = Notifications.unread_counts(user_ids(users))
      assert map_size(unread_counts) == 0
    end
  end

  describe "zip_users_with_unread_counts/1" do
    setup do
      {:ok, users: insert_list(3, :user)}
    end

    test "without notifications", %{users: [%{id: u1_id}, %{id: u2_id}, %{id: u3_id}] = users} do
      assert [{%User{id: ^u1_id}, 0}, {%User{id: ^u2_id}, 0}, {%User{id: ^u3_id}, 0}] =
               Notifications.zip_users_with_unread_counts(users)
    end

    test "with notifications", %{users: [%{id: u1_id}, %{id: u2_id}, %{id: u3_id}] = users} do
      users
      |> Enum.with_index(1)
      |> Enum.each(fn {user, idx} -> insert_list(idx, :notification, recipient: user) end)

      assert [{%User{id: ^u1_id}, 1}, {%User{id: ^u2_id}, 2}, {%User{id: ^u3_id}, 3}] =
               Notifications.zip_users_with_unread_counts(users)
    end

    test "doesn't count read notifications", %{
      users: [%{id: u1_id}, %{id: u2_id}, %{id: u3_id}] = users
    } do
      users
      |> Enum.with_index(1)
      |> Enum.each(fn {user, idx} ->
        insert_list(idx, :notification, recipient: user, unread: false)
      end)

      assert [{%User{id: ^u1_id}, 0}, {%User{id: ^u2_id}, 0}, {%User{id: ^u3_id}, 0}] =
               Notifications.zip_users_with_unread_counts(users)
    end
  end
end
