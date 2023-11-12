defmodule Web.MessageViewTest do
  use Web.ConnCase, async: true
  alias BillBored.Chat

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "message.json without private post" do
    %Chat.Message{
      id: id,
      message: body,
      message_type: message_type,
      parent_id: parent_id,
      created: created,
      is_seen: is_seen,
      user: user
    } = message = insert(:chat_message, message: "such a nice day")

    assert render(Web.MessageView, "message.json", message: message, user: user) == %{
             "message" => %{
               "id" => id,
               "message" => body,
               "media_file_keys" => [],
               "message_type" => message_type,
               "created" => created,
               "reply_to" => %{"id" => parent_id},
               "is_read" => is_seen
             },
             "user" => %{
               :avatar => user.avatar,
               :avatar_thumbnail => user.avatar_thumbnail,
               :first_name => user.first_name,
               :id => user.id,
               :is_ghost => nil,
               :last_name => user.last_name,
               :username => user.username
             }
           }
  end

  test "message.json with private post" do
    media_file = insert(:upload)
    private_post = insert(:post, body: "such a nice day", media_files: [media_file])

    %Chat.Message{
      id: id,
      message: body,
      message_type: message_type,
      parent_id: parent_id,
      created: created,
      is_seen: is_seen,
      user: user
    } =
      message =
      insert(
        :chat_message,
        message: "such a nice day",
        private_post: private_post,
        message_type: "PST"
      )

    assert render(Web.MessageView, "message.json", message: message, user: user) == %{
             "message" => %{
               "id" => id,
               "message" => body,
               "media_file_keys" => [],
               "message_type" => message_type,
               "created" => created,
               "reply_to" => %{"id" => parent_id},
               "is_read" => is_seen,
               "private_post" => %{
                 "id" => private_post.id,
                 "type" => private_post.type,
                 "title" => private_post.title,
                 "media_file_keys" => [
                   %{
                     media: nil,
                     media_key: media_file.media_key,
                     media_thumbnail: nil,
                     media_type: "other",
                     owner: %{
                       avatar: media_file.owner.avatar,
                       avatar_thumbnail: media_file.owner.avatar_thumbnail,
                       first_name: media_file.owner.first_name,
                       id: media_file.owner.id,
                       is_ghost: nil,
                       last_name: media_file.owner.last_name,
                       username: media_file.owner.username
                     }
                   }
                 ]
               }
             },
             "user" => %{
               :avatar => user.avatar,
               :avatar_thumbnail => user.avatar_thumbnail,
               :first_name => user.first_name,
               :id => user.id,
               :is_ghost => nil,
               :last_name => user.last_name,
               :username => user.username
             }
           }
  end
end
