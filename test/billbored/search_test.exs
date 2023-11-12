defmodule BillBored.SearchTest do
  use BillBored.DataCase, async: true
  alias BillBored.Search

  describe "user" do
    setup [:create_users]

    test "finds matched users", %{users: [john2, john, johan, _rick, _travis]} do
      assert [found_john, found_john2, found_jonah] = Search.search_users("john")

      assert found_john.id == john.id
      assert found_john2.id == john2.id
      assert found_jonah.id == johan.id
    end
  end

  describe "hashtag" do
    setup [
      :create_interests,
      :create_tagged_posts,
      :create_tagged_chat_rooms,
      :create_tagged_post_comments,
      :create_tagged_chat_room_messages
    ]

    test "finds posts", %{tagged_posts: [p1, p2, _p3, _p4]} do
      p1_id = p1.id
      p2_id = p2.id

      assert %{posts: [%{id: ^p1_id}]} = Search.search_by_hashtag("food")
      assert %{posts: [%{id: ^p1_id}, %{id: ^p2_id}]} = Search.search_by_hashtag("interest")
    end

    test "finds chat rooms", %{tagged_chat_rooms: [r1, r2, r3]} do
      assert %{chat_rooms: [found_r1]} = Search.search_by_hashtag("food")
      assert found_r1.id == r1.id

      assert %{chat_rooms: [found_r2, found_r3]} = Search.search_by_hashtag("interest")
      assert found_r2.id == r2.id
      assert found_r3.id == r3.id
    end

    test "finds post comments", %{tagged_post_comments: [c1, c2, _c3, _c4, _c5]} do
      c1_id = c1.id
      c2_id = c2.id

      assert %{post_comments: [%{id: ^c1_id}]} = Search.search_by_hashtag("food")

      assert %{post_comments: [%{id: ^c1_id}, %{id: ^c2_id}]} =
               Search.search_by_hashtag("interest")
    end

    test "finds chat room messages", %{tagged_chat_room_messages: [m1, m2]} do
      assert %{chat_room_messages: [found_m1]} = Search.search_by_hashtag("food")
      assert found_m1.id == m1.id
      assert found_m1.room.id == m1.room.id

      assert %{chat_room_messages: [found_m1, found_m2]} = Search.search_by_hashtag("interest")
      assert found_m1.id == m1.id
      assert found_m2.id == m2.id
    end
  end

  describe "post" do
    setup :create_titled_posts

    test "finds posts by title", %{posts: [p1, p2]} do
      assert [found_p2, found_p1] = Search.search_posts("dumb")

      assert found_p1.id == p1.id
      assert found_p2.id == p2.id
    end

    test "finds posts by body", %{posts: [p1, p2]} do
      assert [found_p1, found_p2] = Search.search_posts_content("went to restaurant")

      assert found_p1.id == p1.id
      assert found_p2.id == p2.id
    end
  end

  describe "chat rooms" do
    setup :create_titled_chat_rooms

    test "finds chat rooms by title", %{chat_rooms: [r1, r2]} do
      assert [found_r1, found_r2] = Search.search_chat_rooms("accident")

      assert found_r1.id == r1.id
      assert found_r2.id == r2.id
    end

    # test "finds dropchats by city", %{dropchats: [d1, d2]} do
    # end
  end

  describe "all" do
    setup [
      :create_titled_chat_rooms,
      :create_users,
      :create_interests,
      :create_tagged_posts,
      :create_tagged_chat_rooms,
      :create_tagged_post_comments,
      :create_tagged_chat_room_messages
    ]

    test "finds relevant entities" do
      assert %{
        chat_room_messages: [_],
        users: [],
        posts: [_],
        post_comments: [_],
        chat_rooms: [_]
      } = Search.search_all("food")

      assert %{
        chat_room_messages: [],
        users: users,
        posts: [],
        post_comments: [],
        chat_rooms: []
      } = Search.search_all("john")

      assert length(users) >= 3
    end
  end

  defp create_users(_context) do
    usernames = ["john2", "john", "johan", "rick", "travis"]

    users =
      Enum.map(usernames, fn username ->
        insert(:user, username: username)
      end)

    {:ok, %{users: users}}
  end

  defp create_interests(_context) do
    tags = ["food", "event", "interest", "interest2"]

    interests =
      Enum.map(tags, fn tag ->
        insert(:interest, hashtag: tag)
      end)

    {:ok, %{interests: interests}}
  end

  defp create_tagged_posts(%{interests: [food, event, interest, interest2]}) do
    # needs to be returned both for "#food" and "#interest"
    p1 = insert(:post, private?: false)
    insert(:post_interest, post: p1, interest: food)
    insert(:post_interest, post: p1, interest: interest)

    # needs to be returned once
    p2 = insert(:post, private?: false)
    insert(:post_interest, post: p2, interest: interest)
    insert(:post_interest, post: p2, interest: interest2)

    # won't be found
    p3 = insert(:post, private?: false)
    insert(:post_interest, post: p3, interest: event)

    # is a private post
    p4 = insert(:post, private?: true)
    insert(:post_interest, post: p4, interest: interest)
    insert(:post_interest, post: p4, interest: food)
    insert(:post_interest, post: p4, interest: interest2)

    {:ok, tagged_posts: [p1, p2, p3, p4]}
  end

  defp create_tagged_chat_rooms(%{interests: [food, event, interest, interest2]}) do
    r1 = insert(:chat_room, private: false, interest: food)
    r2 = insert(:chat_room, private: false, interest: interest)
    r3 = insert(:chat_room, private: false, interest: interest2)

    # won't be found
    # _r4 = insert(:chat_room, private: true, interest: interest)
    _r5 = insert(:chat_room, private: false, interest: event)

    {:ok, %{tagged_chat_rooms: [r1, r2, r3]}}
  end

  defp create_tagged_post_comments(%{interests: [food, event, interest, interest2]}) do
    # private post (won't be found)
    private_post = insert(:post, private?: true)

    c1 = insert(:post_comment)
    c2 = insert(:post_comment)
    c3 = insert(:post_comment)
    c4 = insert(:post_comment)
    c5 = insert(:post_comment, post: private_post)

    insert(:post_comment_interest, comment: c1, interest: food)
    insert(:post_comment_interest, comment: c1, interest: interest)

    insert(:post_comment_interest, comment: c2, interest: interest2)

    insert(:post_comment_interest, comment: c3, interest: event)

    insert(:post_comment_interest, comment: c5, interest: food)

    {:ok, %{tagged_post_comments: [c1, c2, c3, c4, c5]}}
  end

  defp create_tagged_chat_room_messages(%{interests: [food, event, interest, interest2]}) do
    # some public rooms
    r1 = insert(:chat_room, private: false)
    r2 = insert(:chat_room, private: false)

    # a private room
    r3 = insert(:chat_room, private: true)

    m1 = insert(:chat_message, room: r1)
    m2 = insert(:chat_message, room: r2)
    m3 = insert(:chat_message, room: r1)

    # won't be found (message in private room)
    m4 = insert(:chat_message, room: r3)

    insert(:chat_message_interest, message: m1, interest: food)
    insert(:chat_message_interest, message: m1, interest: interest)
    insert(:chat_message_interest, message: m2, interest: interest2)

    # won't be found
    insert(:chat_message_interest, message: m3, interest: event)
    insert(:chat_message_interest, message: m4, interest: food)

    {:ok, %{tagged_chat_room_messages: [m1, m2]}}
  end

  defp create_titled_posts(_context) do
    p1 =
      insert(
        :post,
        private?: false,
        title: "dumber",
        body: "he went to a restaurant"
      )

    p2 =
      insert(
        :post,
        private?: false,
        title: "dumb",
        body: "they went out to a restaurant yesterday"
      )

    # won't be found
    _p3 = insert(:post, private?: true, title: "dombb", body: "they went to a place")
    _p4 = insert(:post, private?: false, title: "smart", body: "what is your problem?")

    {:ok, %{posts: [p1, p2]}}
  end

  defp create_titled_chat_rooms(_context) do
    r1 = insert(:chat_room, private: false, title: "accident here")
    r2 = insert(:chat_room, private: false, title: "some accident")

    # won't be found
    _r3 = insert(:chat_room, private: true, title: "accident here")
    _r4 = insert(:chat_room, private: false, title: "somethine else")

    {:ok, %{chat_rooms: [r1, r2]}}
  end
end
