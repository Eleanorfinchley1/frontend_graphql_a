defmodule Web.MessageView do
  use Web, :view
  alias BillBored.{Chat, User, Post}

  def render("index.json", %{messages: messages}) do
    render_many(messages, __MODULE__, "page.json")
  end

  def render("show.json", %{message: message}) do
    render_one(message, __MODULE__, "page.json")
  end

  def render("page.json", %{message: message}) do
    %{
      id: message.id,
      message: message.message,
      is_seen: message.is_seen,
      message_type: message.message_type,
      created: message.created,
      forwarded_message: render_one(message.forwarded_message, __MODULE__, "basic_message.json"),
      parent: render_one(message.replied_to, __MODULE__, "basic_message.json"),
      user: render_one(message.user, Web.UserView, "user.json"),
      room: render_one(message.room, Web.RoomView, "room.json"),
      hashtags: render_many(message.hashtags_interest, Web.InterestView, "show.json"),
      usertags: render_many(message.usertags, Web.UserView, "user.json"),
      users_seen_message: render_many(message.users_seen_message, Web.UserView, "user.json")
    }
  end

  def render("basic_message.json", %{message: %Chat.Message{user: %User{} = user} = message}) do
    render("message.json", %{message: message, user: user})
  end

  def render("message.json", %{
        message: %Chat.Message{
          id: id,
          message: message,
          media_files: media_files,
          message_type: message_type,
          parent_id: parent_id,
          created: created,
          is_seen: is_seen,
          private_post: maybe_private_post
        },
        user: %User{} = user
      }) do
    msg = %{
      "message" => %{
        "id" => id,
        "message" => message,
        # TODO rename to media_files
        "media_file_keys" => sign_media_files(media_files),
        "message_type" => message_type,
        "created" => created,
        "reply_to" => %{"id" => parent_id},
        "is_read" => is_seen
      },
      "user" => Web.UserView.render("user.json", %{user: user})
    }

    case maybe_private_post do
      %Post{
        id: post_id,
        title: post_title,
        type: post_type,
        media_files: media_files,
        eventbrite_urls: eventbrite_urls,
        eventful_id: eventful_id,
        eventful_urls: eventful_urls,
        provider_urls: provider_urls,
        provider_id: provider_id
      } ->
        event_provider_media = cond do
          !is_nil(provider_id) -> provider_urls || []
          !is_nil(eventful_id) -> eventful_urls || []
          true -> eventbrite_urls || []
        end

        all_media = media_files ++ event_provider_media

        put_in(msg, ["message", "private_post"], %{
          "id" => post_id,
          "type" => post_type,
          "title" => post_title,
          "media_file_keys" =>
            Enum.map(all_media, fn media ->
              %{results: [media]} = Web.MediaView.render("show.json", media: media)
              media
            end)
        })

      _other ->
        msg
    end
  end

  def render("created_message.json", %{
        message: %Chat.Message{id: message_id, created: created, parent_id: nil}
      }) do
    %{"id" => message_id, "created" => created}
  end

  def render("created_message.json", %{
        message: %Chat.Message{id: message_id, created: created, parent_id: parent_id}
      }) do
    %Chat.Message{user: %User{username: username, avatar_thumbnail: avatar_thumbnail}} =
      Chat.Message
      |> Repo.get(parent_id)
      |> Repo.preload(:user)

    # after ten minutes
    expires_at = :os.system_time(:seconds) + 10 * 60 * 60

    signed_avatar_thumbnail =
      if avatar_thumbnail do
        Signer.create_signed_url(
          "GET",
          expires_at,
          "/#{System.get_env("GS_MEDIA_BUCKET_NAME")}/#{avatar_thumbnail}"
        )
      end

    %{
      "id" => message_id,
      "reply_to_avatar_thumbnail" => signed_avatar_thumbnail,
      "reply_to_username" => username,
      "created" => created
    }
  end

  def render("messages.json", %{messages: messages}) do
    Enum.map(messages, fn %Chat.Message{user: %User{} = user} = message ->
      render("message.json", %{message: message, user: user})
    end)
  end

  defp sign_media_files([_ | _] = uploads) do
    Enum.map(uploads, fn %BillBored.Upload{media_key: media_key, media: media} = upload ->
      %{
        "media_key" => media_key,
        "media_url" => BillBored.Uploads.File.url({media, upload}, signed: true)
      }
    end)
  end

  defp sign_media_files(_other), do: []
end
