defmodule Web.NGINXController do
  use Web, :controller
  alias BillBored.User

  def publish(conn, %{"name" => livestream_id, "token" => token}) do
    # Delay livestream publishing for 50s
    if Mix.env() != :test do
      :timer.sleep(:timer.seconds(50))
    end

    # sets livestream.active? to true and pushes "livestream:new" to socket
    with %User.AuthToken{user_id: user_id} <- User.AuthTokens.get_by_key(token),
         %BillBored.Livestream{owner_id: ^user_id, id: livestream_id} <-
           BillBored.Livestreams.get(livestream_id) do
      BillBored.Livestreams.InMemory.publish(livestream_id)
      send_resp(conn, 200, [])
    else
      _ ->
        send_resp(conn, 403, [])
    end
  end

  def publish_done(conn, %{"name" => livestream_id}) do
    BillBored.Livestreams.InMemory.publish_done(livestream_id)
    send_resp(conn, 200, [])
  end
end
