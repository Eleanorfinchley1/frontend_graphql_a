defmodule Web.Plugs.Context do
  @moduledoc """
  Reads user id from bearer token.
  """

  @behaviour Plug
  use Web, :plug
  alias BillBored.User

  def init(opts) do
    Keyword.take(opts, [:allow_restricted]) |> Enum.into(%{})
  end

  # TODO refactor
  def call(%Plug.Conn{req_headers: req_headers} = conn, opts) do
    case :proplists.get_value("authorization", req_headers) do
      "Bearer " <> token ->
        case User.AuthTokens.get_by_key(token) do
          %User.AuthToken{user: %User{} = user} ->
            conn
            |> maybe_halt_on_banned_user(user, opts)
            |> maybe_halt_on_deleted_user(user, opts)
            |> maybe_halt_on_restricted_user(user, opts)
            |> maybe_assign_context(user)

          _ ->
            conn
            |> send_resp(:forbidden, "invalid token")
            |> halt()
        end

      :undefined ->
        assign(conn, :user_id, nil)

      _ ->
        conn
        |> put_resp_header("www-authenticate", "Bearer")
        |> send_resp(:unauthorized, "")
        |> halt()
    end
  end

  defp maybe_halt_on_deleted_user(%Plug.Conn{halted: false} = conn, %{deleted?: true}, _opts) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(
      :forbidden,
      Jason.encode!(%{
        success: false,
        error: "deleted",
        reason: "This user account was deleted"
      })
    )
    |> halt()
  end

  defp maybe_halt_on_deleted_user(conn, _user, _opts), do: conn

  defp maybe_halt_on_banned_user(%Plug.Conn{halted: false} = conn, %{banned?: true}, _opts) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(
      :forbidden,
      Jason.encode!(%{
        success: false,
        error: "banned",
        reason: "This user account was banned"
      })
    )
    |> halt()
  end

  defp maybe_halt_on_banned_user(conn, _user, _opts), do: conn

  defp maybe_halt_on_restricted_user(%Plug.Conn{halted: false} = conn, _user, %{allow_restricted: true}), do: conn
  defp maybe_halt_on_restricted_user(%Plug.Conn{halted: false} = conn, %User{flags: %{"access" => "restricted"} = flags}, _opts) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(
      :forbidden,
      Jason.encode!(%{
        success: false,
        error: "access_restricted",
        reason: flags["restriction_reason"] || "Access temporarily restricted"
      })
    )
    |> halt()
  end

  defp maybe_halt_on_restricted_user(conn, _user, _opts), do: conn

  defp maybe_assign_context(%Plug.Conn{halted: false} = conn, %User{id: user_id} = user) do
    BillBored.Users.OnlineTracker.update_user_online_status(user)

    conn
    |> assign(:user_id, user_id)
    |> assign(:user_registration_status, BillBored.Users.registration_status(user))
  end

  defp maybe_assign_context(conn, _user), do: conn
end
