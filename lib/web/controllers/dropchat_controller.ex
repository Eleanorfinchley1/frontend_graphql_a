defmodule Web.DropchatController do
  use Web, :controller

  require Logger

  alias BillBored.Chat
  alias Chat.Rooms
  alias Chat.Room.{ElevatedPrivileges, ElevatedPrivilege}
  alias BillBored.Chat.Room.DropchatStreams

  action_fallback Web.FallbackController

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def grant_request(conn, %{"request_id" => request_id}, current_user_id) do
    case ElevatedPrivileges.grant(request_id, by: current_user_id) do
      {:ok, %{granted_privilege: %ElevatedPrivilege{} = granted_privilege}} ->
        render(conn, "granted_privilege.json", granted_privilege: granted_privilege)

      {:error, :admin?, false, _changes} ->
        conn
        |> put_status(:forbidden)
        |> json(%{"error" => "not an admin"})

      {:error, :request, :not_found, _changes} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => "request not found"})
    end
  end

  def dropchat_feed(conn, params, user_id) do
    geometry = Map.get(params, "geometry")
    count = Map.get(params, "count", 20)
    page = Map.get(params, "page", 0)

    data = %{rooms: Rooms.get_dropchats(user_id, geometry, count, page)}

    conn
    |> put_view(Web.RoomView)
    |> render("index.json", data)
  end

  @dropchat_list_params [
    {"page", :page, false, :integer},
    {"page_size", :page_size, false, :integer}
  ]

  def dropchat_list(conn, params, user_id) do
    with {:ok, valid_params} <- validate_params(@dropchat_list_params, params) do
      data = %{
        rooms: Rooms.get_all_dropchats(user_id, valid_params[:page] || 1, valid_params[:page_size] || 10)
      }

      conn
      |> put_view(Web.RoomView)
      |> render("index.json", data)
    end
  end

  @user_streams_params [
    {"user_id", :user_id, true, :integer},
    {"page", "page", false, :integer},
    {"page_size", "page_size", false, :integer},
  ]

  def user_stream_recordings(conn, params, _) do
    with {:ok, params} <- validate_params(@user_streams_params, params) do
      paginated_result = DropchatStreams.list_with_recordings_for(params[:user_id], Map.take(params, ~w(page page_size)))
      render(conn, "user_streams.json", paginated_result)
    end
  end

  @remove_stream_recordings_params [
    {"stream_id", :stream_id, true, :integer}
  ]

  def remove_stream_recordings(conn, params, user_id) do
    with {:ok, params} <- validate_params(@remove_stream_recordings_params, params),
         {:ok, stream} <- DropchatStreams.get(params[:stream_id]),
         true <- Web.Policies.DropchatControllerPolicy.authorize(:remove_stream_recordings, user_id, stream),
         {:ok, _updated_stream} <- DropchatStreams.remove_recording(stream) do
      json(conn, %{success: true})
    else
      {false, reason} ->
        Logger.debug("Can't remove stream recordings: #{inspect(reason)}")

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(403, Jason.encode!(%{success: false}))

      error ->
        error
    end
  end
end
