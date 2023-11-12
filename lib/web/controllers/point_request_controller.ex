defmodule Web.PointRequestController do
  use Web, :controller

  alias BillBored.{Users, UserPoints, UserPointRequests}

  require Logger

  action_fallback Web.FallbackController

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def create(conn, params, user_id) do
    with {:ok, request} <- UserPointRequests.create(params, user_id: user_id) do
      friend_ids = Users.list_friend_ids(user_id)
      mentor_ids = []
      fellow_ids = Users.list_fellow_ids(user_id)
      receiver_ids = friend_ids ++ mentor_ids ++ fellow_ids |> Enum.uniq()
      user = Users.get(user_id)
      Notifications.process_points_request(request: request, from: user, to: receiver_ids)
      render(conn, "show.json", request: request)
    end
  end

  @donate_params [
    {"request_id", :request_id, true, :integer},
    {"stream_points", :stream_points, true, :integer}
  ]

  def donate(conn, params, user_id) do
    with {:ok, params} <- validate_params(@donate_params, params),
         point_request <- UserPointRequests.get(params[:request_id]),
         true <- length(point_request.donations) < 3 and point_request.user_id != user_id,
         {:ok, sender_audit, receiver_audit} <- UserPoints.donate_stream_points(user_id, point_request.user_id, params[:stream_points]),
         {:ok, donation} <- UserPointRequests.create_donation(params, receiver_id: point_request.user_id, sender_id: user_id) do
      Notifications.process_points_donation(donation: donation, sender_audit: sender_audit, receiver_audit: receiver_audit)
      json(conn, %{success: true})
    else
      {:error, reason} ->
        Logger.debug("Can't donate stream points: #{inspect(reason)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(422, Jason.encode!(%{success: false}))

      false ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{success: false}))

      error ->
        error
    end
  end
end
