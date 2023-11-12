defmodule Web.LivestreamChannelTest do
  use Web.ChannelCase

  import Ecto.Query

  alias BillBored.{Livestream, Livestreams, User}

  setup do
    %User.AuthToken{user: %User{} = owner, key: token} = insert(:auth_token)

    %Livestream{} =
      livestream =
      insert(:livestream, owner: owner, location: %BillBored.Geo.Point{lat: 30, long: 32})

    {:ok, %Phoenix.Socket{} = socket} = connect(Web.UserSocket, %{"token" => token})

    %{owner: owner, livestream: livestream, socket: socket, spectators: []}
  end

  describe "join" do
    test "as owner", %{socket: socket, livestream: livestream, owner: owner} do
      refute BillBored.Livestreams.InMemory.exists?(livestream.id)

      {:ok, _reply, %Phoenix.Socket{} = socket} =
        subscribe_and_join(socket, "livestream:#{livestream.id}", %{})

      assert socket.assigns.livestream_id == livestream.id
      assert socket.assigns.user.id == owner.id
      assert socket.assigns.owner?

      assert BillBored.Livestreams.InMemory.exists?(livestream.id)
    end

    test "as spectator", %{socket: socket, livestream: livestream} do
      # "starts" stream for owner
      {:ok, _reply, _owner_socket} =
        subscribe_and_join(socket, "livestream:#{livestream.id}", %{})

      assert BillBored.Livestreams.InMemory.get(:viewers_count, livestream.id) == 0

      # add three spectators
      # TODO refactor
      spectator_info1 = add_spectator(livestream)
      spectator_info2 = add_spectator(livestream)
      spectator_info3 = add_spectator(livestream)

      assert BillBored.Livestreams.InMemory.get(:viewers_count, livestream.id) == 3

      assert spectator_info1.spectator_socket.assigns.livestream_id == livestream.id
      refute spectator_info1.spectator_socket.assigns.owner?

      assert spectator_info2.spectator_socket.assigns.livestream_id == livestream.id
      refute spectator_info2.spectator_socket.assigns.owner?

      assert spectator_info3.spectator_socket.assigns.livestream_id == livestream.id
      refute spectator_info3.spectator_socket.assigns.owner?
    end

    test "livestream that doesn't not exist", %{socket: socket} do
      assert {:error, %{"detail" => "livestream not found"}} ==
               subscribe_and_join(socket, "livestream:#{Ecto.UUID.generate()}", %{})
    end

    # TODO
    # test "with invalid livestream id", %{socket: socket} do
    #   assert_raise Ecto.Query.CastError, ~r/cannot be cast to type :id in query/, fn ->
    #     subscribe_and_join(socket, "livestreams:adsf", %{})
    #   end
    # end
  end

  describe "leave" do
    setup :join_livestream

    @tag :skip
    test "as owner", %{socket: socket, livestream: %Livestream{id: livestream_id} = livestream} do
      assert BillBored.Livestreams.InMemory.exists?(livestream.id)
      %{spectator_socket: spectator_socket} = add_spectator(livestream)

      {:ok, _reply, _spectator_socket} =
        subscribe_and_join(spectator_socket, "livestreams", %{
          "geometry" => %{
            "type" => "Point",
            "coordinates" => [30, 33]
          },
          "radius" => 60_000
        })

      leave(socket)

      assert_push("livestream:over", %{"id" => ^livestream_id})
      assert_broadcast("livestream:over", %{})

      # TODO find a better way
      :timer.sleep(10)

      refute BillBored.Livestreams.InMemory.exists?(livestream.id)
    end

    test "as spectator", %{livestream: livestream} do
      assert BillBored.Livestreams.InMemory.exists?(livestream.id)
      assert BillBored.Livestreams.InMemory.get(:viewers_count, livestream.id) == 0

      %{spectator_socket: spectator_socket} = add_spectator(livestream)

      assert BillBored.Livestreams.InMemory.get(:viewers_count, livestream.id) == 1

      Process.flag(:trap_exit, true)
      leave(spectator_socket)
      # TODO find a better way
      :timer.sleep(10)

      assert BillBored.Livestreams.InMemory.get(:viewers_count, livestream.id) == 0
    end
  end

  describe "comment" do
    setup :join_livestream

    test "create with valid params", %{
      socket: socket,
      livestream: %Livestream{id: livestream_id},
      owner: %User{id: author_id} = author
    } do
      # ensures there is no such comment before the test
      refute Livestreams.get_comment_by(body: "hello", livestream_id: livestream_id)

      comment = %{"body" => "hello"}
      ref = push(socket, "comment:new", comment)
      assert_reply(ref, :ok)

      # ensures comment was saved
      assert %Livestream.Comment{
               author_id: ^author_id,
               body: "hello",
               livestream_id: ^livestream_id
             } =
               saved_comment =
               Livestreams.get_comment_by(body: "hello", livestream_id: livestream_id)

      assert_broadcast("comment:new", rendered_comment)

      assert rendered_comment ==
               Web.LivestreamView.render("comment.json", %{comment: saved_comment, author: author})
    end
  end

  describe "comment list with comment votes and current user vote mark" do
    setup :join_livestream

    test "create with valid params", %{
      socket: socket,
      livestream: %Livestream{} = livestream,
      owner: %User{id: author_id} = author
    } do
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)
      user4 = insert(:user)
      user5 = insert(:user)

      saved_comment =
        insert(:livestream_comment, author: author, body: "hello", livestream: livestream)

      saved_comment2 =
        insert(:livestream_comment, author: author, body: "hello2", livestream: livestream)

      Livestreams.create_or_update_comment_vote(author_id, saved_comment.id, "upvote")
      Livestreams.create_or_update_comment_vote(author_id, saved_comment.id, "upvote")
      Livestreams.create_or_update_comment_vote(user1.id, saved_comment.id, "upvote")
      Livestreams.create_or_update_comment_vote(user1.id, saved_comment.id, "")
      Livestreams.create_or_update_comment_vote(user2.id, saved_comment.id, "downvote")
      Livestreams.create_or_update_comment_vote(user2.id, saved_comment.id, "downvote")
      Livestreams.create_or_update_comment_vote(user3.id, saved_comment.id, "upvote")
      Livestreams.create_or_update_comment_vote(user3.id, saved_comment.id, "downvote")
      Livestreams.create_or_update_comment_vote(user4.id, saved_comment.id, "upvote")
      Livestreams.create_or_update_comment_vote(user4.id, saved_comment.id, "downvote")
      Livestreams.create_or_update_comment_vote(user5.id, saved_comment.id, "upvote")
      Livestreams.create_or_update_comment_vote(user5.id, saved_comment.id, "downvote")

      Livestreams.create_or_update_comment_vote(author_id, saved_comment2.id, "upvote")
      Livestreams.create_or_update_comment_vote(author_id, saved_comment2.id, "downvote")
      Livestreams.create_or_update_comment_vote(user1.id, saved_comment2.id, "upvote")
      Livestreams.create_or_update_comment_vote(user1.id, saved_comment2.id, "")
      Livestreams.create_or_update_comment_vote(user2.id, saved_comment2.id, "downvote")
      Livestreams.create_or_update_comment_vote(user2.id, saved_comment2.id, "upvote")
      Livestreams.create_or_update_comment_vote(user3.id, saved_comment2.id, "upvote")
      Livestreams.create_or_update_comment_vote(user3.id, saved_comment2.id, "upvote")
      Livestreams.create_or_update_comment_vote(user4.id, saved_comment2.id, "downvote")
      Livestreams.create_or_update_comment_vote(user4.id, saved_comment2.id, "upvote")
      Livestreams.create_or_update_comment_vote(user5.id, saved_comment2.id, "upvote")
      Livestreams.create_or_update_comment_vote(user5.id, saved_comment2.id, "downvote")

      ref = push(socket, "comments:list", %{})

      comments = [
        %{
          author: author.username,
          body: "hello",
          current_user_downvote: 0,
          current_user_upvote: 1,
          downvote: 4,
          id: saved_comment.id,
          upvote: 1
        },
        %{
          author: author.username,
          body: "hello2",
          current_user_downvote: 1,
          current_user_upvote: 0,
          downvote: 2,
          id: saved_comment2.id,
          upvote: 3
        }
      ]

      assert_reply(ref, :ok, %{comments: ^comments})
    end
  end

  describe "vote" do
    setup :join_livestream

    test "create with valid params", %{
      socket: socket,
      livestream: %Livestream{id: livestream_id},
      owner: %User{id: user_id} = _user
    } do
      # ensures there is no such downvote before the test
      refute Repo.get_by(Livestream.Vote, user_id: user_id, livestream_id: livestream_id)

      ref = push(socket, "vote:new", %{"vote_type" => "downvote"})
      assert_reply(ref, :ok)

      # ensures downvote was saved
      assert %Livestream.Vote{
               user_id: ^user_id,
               livestream_id: ^livestream_id
             } =
               _saved_upvote =
               Repo.get_by(Livestream.Vote, user_id: user_id, livestream_id: livestream_id)

      assert_broadcast("change_votes", rendered_upvote)
      assert rendered_upvote == %{downvotes: 1, upvotes: 0}
    end
  end

  describe "comment_vote" do
    setup :join_livestream

    test "create with valid params", %{
      socket: socket,
      livestream: %Livestream{} = livestream,
      owner: %User{id: user_id} = author
    } do
      %Livestream.Comment{id: comment_id} =
        insert(:livestream_comment, author: author, body: "hello", livestream: livestream)

      # ensures there is no such upvote before the test
      refute Repo.get_by(Livestream.Comment.Vote, user_id: user_id, comment_id: comment_id)

      ref =
        push(socket, "comment_vote:new", %{"vote_type" => "upvote", "comment_id" => comment_id})

      assert_reply(ref, :ok)

      # ensures upvote was saved
      assert %Livestream.Comment.Vote{
               user_id: ^user_id,
               comment_id: ^comment_id
             } =
               _saved_upvote =
               Repo.get_by(Livestream.Comment.Vote, user_id: user_id, comment_id: comment_id)

      assert_broadcast("comment:change_votes", rendered_upvote)
      assert rendered_upvote == %{comment_id: comment_id, downvotes: 0, upvotes: 1}
    end
  end

  describe "info" do
    setup :join_livestream

    test "viewers_count", %{socket: socket, livestream: livestream} do
      ref = push(socket, "livestream:info", %{})

      assert_reply(ref, :ok, %{
        online_viewers_count: 0,
        views_count: 1,
        current_user_votes: [%{downvote: 0, upvote: 0}]
      })

      %{spectator_socket: ss} = add_spectator(livestream)

      ref = push(socket, "livestream:info", %{})
      assert_reply(ref, :ok, %{online_viewers_count: 1, views_count: 2})

      Process.flag(:trap_exit, true)
      leave(ss)

      :timer.sleep(10)

      ref = push(socket, "livestream:info", %{})
      assert_reply(ref, :ok, %{online_viewers_count: 0, views_count: 2})

      l_id = livestream.id

      Livestream
      |> where(id: ^l_id)
      |> Repo.update_all(set: [recorded?: true])

      add_spectator(livestream)
      add_spectator(livestream)
      ref = push(socket, "livestream:info", %{})
      assert_reply(ref, :ok, %{online_viewers_count: 0, views_count: 4})
    end
  end

  defp join_livestream(%{livestream: livestream, socket: socket}) do
    {:ok, _reply, %Phoenix.Socket{} = socket} =
      subscribe_and_join(socket, "livestream:#{livestream.id}", %{})

    {:ok, %{socket: socket}}
  end

  defp add_spectator(livestream) do
    %User.AuthToken{user: %User{} = spectator, key: token} = insert(:auth_token)
    {:ok, %Phoenix.Socket{} = spectator_socket} = connect(Web.UserSocket, %{"token" => token})

    {:ok, _reply, %Phoenix.Socket{} = spectator_socket} =
      subscribe_and_join(spectator_socket, "livestream:#{livestream.id}", %{})

    %{spectator: spectator, spectator_socket: spectator_socket}
  end
end
