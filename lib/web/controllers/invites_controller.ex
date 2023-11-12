defmodule Web.InvitesController do
  use Web, :controller

  alias BillBored.{Invites, Users}

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def index(conn, _params, user_id) do
    case Invites.get_invites_by_user_id(user_id) do
      [] ->
        send_resp(conn, 404, Jason.encode!([], pretty: true))

      invites ->
        render(conn, "index.json", invites: invites)
    end
  end

  def create(conn, %{"_json" => emails}, user_id) when is_list(emails) do
    send_resp(
      conn,
      200,
      Jason.encode!(
        Enum.map(emails, fn email -> check_invites(email, user_id) end),
        pretty: true
      )
    )
  end

  def create(conn, %{"email" => email}, user_id)
      when not is_binary(email) and not is_nil(user_id) do
    send_resp(conn, 200, Jason.encode!(check_invites(email, user_id), pretty: true))
  end

  defp check_invites(email, user_id) do
    case Users.get_by(email: email) do
      %BillBored.User{} ->
        %{email: email, success: false, message: "User is already a member of Billbored."}

      nil ->
        case Invites.get_by_invites(%{email: email}) do
          %Invites.Invite{} ->
            %{
              email: email,
              success: false,
              message: "You had already sent an Invite to this user"
            }

          nil ->
            {:ok, _invite} = Invites.create_invite(%{email: email, user_id: user_id})

            Mail.send_invite(email, %{email: email, username: Users.get_by_id(user_id).username})
            %{email: email, success: true, message: "Sent"}
        end
    end
  end
end
