defmodule Web.NotificationChannel do
  use Web, :channel
  alias BillBored.{User, Post, Chat, UserPointRequest}

  @impl true
  def join(
        "notifications:" <> user_id,
        _params,
        %{assigns: %{user: %User{} = user}} = socket
      ) do
    if String.to_integer(user_id) == user.id do
      {:ok, socket}
    else
      {:error, %{"reason" => "Forbidden"}}
    end
  end

  def notify_of_post_comment(%Post.Comment{
        id: comment_id,
        post: %Post{id: post_id, author: %User{id: post_author_id}},
        author: %User{username: comment_author_username, id: comment_author_id}
      }) do
    Web.Endpoint.broadcast("notifications:#{post_author_id}", "posts:comment", %{
      "comment" => %{
        "id" => comment_id,
        "post" => %{"id" => post_id},
        "author" => %{"id" => comment_author_id, "username" => comment_author_username}
      }
    })
  end

  def notify_of(:new_popular_post, %Post{id: post_id, title: post_title}, receivers) do
    payload = %{
      "post" => %{
        "id" => post_id,
        "title" => post_title
      }
    }

    Enum.each(receivers, fn %User{id: user_id} ->
      Web.Endpoint.broadcast("notifications:#{user_id}", "posts:new:popular", payload)
    end)
  end

  def notify_of(:new_popular_dropchat, %Chat.Room{id: room_id, title: title}, receivers) do
    payload = %{
      "room" => %{
        "id" => room_id,
        "title" => title
      }
    }

    Enum.each(receivers, fn %User{id: user_id} ->
      Web.Endpoint.broadcast("notifications:#{user_id}", "dropchats:new:popular", payload)
    end)
  end

  def notify_of(%Post.ApprovalRequest{} = request) do
    payload = %{
      "post_id" => request.post_id,
      "requester_id" => request.requester_id,
      "message" => "#{request.requester.username} requested your approval for a post"
    }

    Web.Endpoint.broadcast(
      "notifications:#{request.approver_id}",
      "posts:approve:request",
      payload
    )
  end

  def notify_of(%Post.ApprovalRequest.Rejection{} = rejection) do
    payload = %{
      "post_id" => rejection.post_id,
      "approver_id" => rejection.approver_id,
      "message" => "#{rejection.approver.username} rejected your post"
    }

    Web.Endpoint.broadcast(
      "notifications:#{rejection.requester_id}",
      "posts:approve:request:reject",
      payload
    )
  end

  def notify_of(:requested_stream_points, %UserPointRequest{id: request_id}, %User{} = user, receiver_ids) do
    Enum.each(receiver_ids, fn receiver_id ->
      Web.Endpoint.broadcast("notifications:#{receiver_id}", "points:request", %{
        request_id: request_id,
        user: user |> Map.take([:id, :username, :first_name, :last_name, :avatar]),
        message: "has requested streaming points"
      })
    end)
  end

end
