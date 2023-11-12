defmodule Web.BusinessAccounts.FollowersController do
  use Web, :controller
  require Logger
  alias BillBored.BusinessAccounts.Followers.Policy

  action_fallback(Web.FallbackController)

  def history(%{assigns: %{user_id: user_id}} = conn, %{"business_id" => business_id} = params) do
    case Policy.authorize(:history, params, user_id) do
      true ->
        history = BillBored.Users.business_followers_history(business_id)
        json(conn, Web.BusinessAccounts.FollowersView.render("history.json", %{history: history}))

      {false, reason} ->
        Logger.debug("Access denied to business followers history: #{inspect(reason)}")
        send_resp(conn, 403, [])
    end
  end
end
