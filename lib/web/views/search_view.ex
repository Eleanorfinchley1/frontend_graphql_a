defmodule Web.SearchView do
  use Web, :view
  alias BillBored.{Chat, Post}

  def render("search_result.json", %{
        users: users,
        posts: posts,
        post_comments: post_comments,
        chat_rooms: chat_rooms,
        chat_room_messages: chat_room_messages
      }) do
    %{
      "users" => Enum.map(users, &Web.UserView.render("user.json", %{user: &1})),
      "posts" =>
        Enum.map(posts, fn %Post{id: post_id, title: title, body: body, type: post_type} ->
          %{
            "id" => post_id,
            "title" => title,
            "body" => body,
            "type" => post_type
          }
        end),
      "post_comments" =>
        Enum.map(post_comments, &Web.PostCommentView.render("show.json", %{comment: &1})),
      "chat_rooms" =>
        Enum.map(chat_rooms, fn %Chat.Room{id: room_id, title: title} ->
          %{
            "id" => room_id,
            "title" => title
          }
        end),
      "chat_room_messages" =>
        Enum.map(chat_room_messages, fn %Chat.Message{
                                          id: message_id,
                                          message: message,
                                          room: %Chat.Room{id: room_id, title: room_title}
                                        } ->
          %{
            "id" => message_id,
            "message" => message,
            "room" => %{
              "id" => room_id,
              "title" => room_title
            }
          }
        end)
    }
  end
end
