defmodule Web.NotificationControllerTest do
  use Web.ConnCase, async: true
  alias BillBored.{Notification, Notifications}
  import BillBored.Factory

  # @post_params %{
  #   "title" => "Poll",
  #   "private" => false,
  #   "media_file_keys" => [],
  #   "items" => [
  #     %{"media_file_keys" => [], "title" => "poll1"},
  #     %{"media_file_keys" => [], "title" => "poll2"}
  #   ],
  #   "location" => %{"type" => "Point", "coordinates" => [30.7008, 76.7885]},
  #   "body" => "Wegerger her ",
  #   "fake" => false
  # }

  describe "index" do
    setup %{conn: conn} do
      %{user: user, key: token} = insert(:auth_token)
      {:ok, conn: authenticate(conn, token), user: user}
    end

    test "with notifications of all kinds", %{conn: conn, user: user} do
      # posts:new:popular
      popular_post = insert(:post)
      assert {1, nil} == Notifications.create_for(:new_popular_post, popular_post, [user])

      # dropchats:new:popular
      popular_dropchat = insert(:chat_room)
      assert {1, nil} == Notifications.create_for(:new_popular_dropchat, popular_dropchat, [user])

      # posts:like
      post_upvote = insert(:post_upvote, post: build(:post, author: user))
      assert {:ok, %Notification{}} = Notifications.create_for(post_upvote)

      # posts:reacted
      post_downvote = insert(:post_downvote, post: build(:post, author: user))
      assert {:ok, %Notification{}} = Notifications.create_for(post_downvote)

      # post:comments:like
      post_comment_upvote =
        insert(:post_comment_upvote, comment: build(:post_comment, author: user))

      assert {:ok, %Notification{}} = Notifications.create_for(post_comment_upvote)

      # post:comments:reacted
      post_comment_downvote =
        insert(:post_comment_downvote, comment: build(:post_comment, author: user))

      assert {:ok, %Notification{}} = Notifications.create_for(post_comment_downvote)

      # posts:comment
      post_comment = insert(:post_comment, post: build(:post, author: user))
      assert {:ok, %Notification{}} = Notifications.create_for(post_comment)

      # posts:approve:request
      post_approval_request = insert(:post_approval_request, approver: user)
      assert {:ok, %Notification{}} = Notifications.create_for(post_approval_request)

      # posts:approve:request:reject
      post_approval_request_rejection = insert(:post_approval_request_rejection, requester: user)
      assert {:ok, %Notification{}} = Notifications.create_for(post_approval_request_rejection)

      # chats:privilege:granted
      chat_room_elevated_privilege = insert(:chat_room_elevated_privilege, user: user)
      assert {:ok, %Notification{}} = Notifications.create_for(chat_room_elevated_privilege)

      # chats:privilege:request
      chat_room_elevated_privileges_request =
        insert(:chat_room_elevated_privileges_request,
          room: build(:chat_room, administrators: [user])
        )

      assert {1, _} = Notifications.create_for(chat_room_elevated_privileges_request)

      # chats:message:tagged
      tagged_message = insert(:chat_message, message: "@#{user.username} what do you think?")

      assert {1, _} =
               Notifications.create_for(
                 {:chat_tagged,
                  %{
                    tagger: tagged_message.user,
                    message: tagged_message,
                    room: tagged_message.room,
                    receivers: [user]
                  }}
               )

      # chats:message:reply

      question = insert(:chat_message, message: "what do you think?", user: user)
      reply = insert(:chat_message, message: "not sure", room: question.room)

      assert {:ok, %Notification{}} =
               Notifications.create_for(
                 {:chat_reply,
                  sender: reply.user,
                  replied_to_message: question,
                  reply: reply,
                  room: question.room,
                  muted?: false}
               )

      # events:matching_interests
      interesting_event = insert(:event)

      assert {1, _} =
               Notifications.create_for(
                 {:event_matching_interests, event: interesting_event, receivers: [user]}
               )

      # following:new
      following = insert(:user_following, to: user)
      assert {:ok, %Notification{}} = Notifications.create_for(following)

      # poll_vote:new
      poll = insert(:poll, post: build(:post, author: user))
      poll_vote = insert(:poll_item_vote, poll_item: %{hd(poll.items) | poll: poll})
      assert {:ok, %Notification{}} = Notifications.create_for(poll_vote)

      # event:attendant:new
      new_event_attendant =
        insert(:event_attendant,
          status: "accepted",
          event: build(:event, post: build(:post, author: user))
        )

      assert {:ok, %Notification{}} = Notifications.create_for(new_event_attendant)

      # event:approaching
      approaching_event_attendant =
        insert(:event_attendant,
          status: "accepted",
          event: build(:event, date: DateTime.add(DateTime.utc_now(), 12 * 3600)),
          user: user
        )

      assert {:ok, %Notification{}} =
               Notifications.create_for({:event_approaching, approaching_event_attendant})


      # area_notifications:scheduled
      timetable_run = insert(:area_notifications_timetable_run)

      assert {_, [_notification]} = Notifications.create_for({:scheduled_area_notifications, %{
        template: "Hello!",
        timetable_runs: [timetable_run],
        receivers: [user]
      }})

      # dropchats:new:followed
      dropchat = insert(:chat_room, chat_type: "dropchat", title: "Title!")

      assert {_, [_notification]} = Notifications.create_for({:dropchat_created, %{
        admin_user: insert(:user),
        room: dropchat,
        receivers: [user]
      }})

      # access:granted
      assert {:ok, _notification} = Notifications.create_for({:user_access_granted, user})

      # dropchats:streams:new:followed
      dropchat = insert(:chat_room, chat_type: "dropchat", title: "Title!")
      admin = insert(:user)
      stream =
        insert(:dropchat_stream, dropchat: dropchat, admin: admin)
        |> Repo.preload([:admin, :dropchat])

      assert {_, [_notification]} = Notifications.create_for({:dropchat_stream_started, %{
        admin_user: admin,
        room_key: dropchat.key,
        stream: stream,
        receivers: [user]
      }})

      # now test
      assert %{
               "entries" => _notifications,
               "next" => nil,
               "page_number" => 1,
               "page_size" => 25,
               "prev" => nil,
               "total_entries" => 22,
               "total_pages" => 1
             } =
               conn
               |> get(Routes.notification_path(conn, :index, page_size: 25))
               |> doc(
                 description: "with a notification of each type",
                 operation_id: "notifications_index"
               )
               |> json_response(200)
    end
  end

  describe "notifications are returned" do
    setup [:create_users]

    test "being paginated", %{conn: conn, tokens: tokens} do
      [author, other | _] = tokens

      post = insert(:post, author: author.user)

      params = %{
        "post_id" => post.id,
        "body" => "COMMENT BODY"
      }

      for _ <- 1..10 do
        conn
        |> authenticate(other)
        |> post(Routes.post_comment_path(conn, :create, post.id), params)
        |> response(200)
      end

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index))
        |> json_response(200)

      assert resp["total_entries"] == 10

      # providing "filter=unread":

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index), filter: "unread")
        |> json_response(200)

      assert resp["total_entries"] == 10

      # marking all as read:

      conn
      |> authenticate(author)
      |> post(Routes.notification_path(conn, :update), mark_all_read: true)
      |> response(200)

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index), filter: "unread")
        |> json_response(200)

      assert resp["total_entries"] == 0
    end
  end

  describe "notifications are created" do
    setup [:create_users]

    test "when post is commented", %{conn: conn, tokens: tokens} do
      [author, other | _] = tokens

      post = insert(:post, author: author.user)

      params = %{
        "post_id" => post.id,
        "body" => "COMMENT BODY"
      }

      conn
      |> authenticate(other)
      |> post(Routes.post_comment_path(conn, :create, post.id), params)
      |> response(200)

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index))
        |> json_response(200)

      assert resp["total_entries"] == 1
    end

    test "when post is upvoted/downvoted", %{conn: conn, tokens: tokens} do
      [author, other | _] = tokens

      post = insert(:post, author: author.user)

      # upvote

      conn
      |> authenticate(other)
      |> post(Routes.post_path(conn, :vote, post.id), %{action: "upvote"})
      |> response(204)

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index))
        |> json_response(200)

      assert resp["total_entries"] == 1

      # downvote

      conn
      |> authenticate(other)
      |> post(Routes.post_path(conn, :vote, post.id), %{action: "downvote"})
      |> response(204)

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index))
        |> json_response(200)

      assert resp["total_entries"] == 1
    end

    test "when post comment is upvoted/downvoted", %{conn: conn, tokens: tokens} do
      [author, other | _] = tokens

      comment = insert(:post_comment, author: author.user)

      # upvote

      conn
      |> authenticate(other)
      |> post(Routes.post_comment_path(conn, :vote, comment.id), %{action: "upvote"})
      |> response(204)

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index))
        |> json_response(200)

      assert resp["total_entries"] == 1

      # downvote

      conn
      |> authenticate(other)
      |> post(Routes.post_comment_path(conn, :vote, comment.id), %{action: "downvote"})
      |> response(204)

      resp =
        conn
        |> authenticate(author)
        |> get(Routes.notification_path(conn, :index))
        |> json_response(200)

      assert resp["total_entries"] == 1
    end
  end

  defp create_users(_context) do
    tokens = for _ <- 1..10, do: insert(:auth_token)
    {:ok, %{tokens: tokens}}
  end
end
