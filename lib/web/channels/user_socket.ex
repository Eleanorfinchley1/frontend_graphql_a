defmodule Web.UserSocket do
  use Web, :socket
  alias BillBored.User

  ## Channels

  channel("chats:*", Web.ChatChannel)
  channel("livestream:*", Web.LivestreamChannel)
  channel("dropchats:*", Web.DropchatChannel)
  channel("posts:*", Web.PostChannel)

  # TODO rename to "rooms"
  channel("chats:lobby", Web.RoomChannel)
  # channel("messages", Web.MessageChannel)
  channel("dropchats", Web.DropchatsChannel)
  channel("friends", Web.FriendChannel)
  channel("livestreams", Web.LivestreamsChannel)
  channel("posts", Web.PostChannel)
  channel("personalized", Web.PersonalizedPostChannel)
  channel("offers", Web.OffersChannel)
  channel("search", Web.SearchChannel)
  channel("notifications:*", Web.NotificationChannel)
  channel("area_notifications:*", Web.AreaNotificationChannel)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket) when is_binary(token) do
    case User.AuthTokens.get_by_key(token) do
      %User.AuthToken{user: %User{banned?: true}} -> :error
      %User.AuthToken{user: %User{deleted?: true}} -> :error
      %User.AuthToken{user: %User{flags: %{"access" => "restricted"}}} -> :error
      %User.AuthToken{user: %User{} = user} -> {:ok, assign(socket, :user, user)}
      nil -> :error
    end
  end

  def connect(_params, _socket) do
    :error
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Web.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(%Phoenix.Socket{assigns: %{user: %User{id: user_id}}}) do
    "user_socket:#{user_id}"
  end
end
