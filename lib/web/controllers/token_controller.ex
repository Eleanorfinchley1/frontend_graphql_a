defmodule Web.TokenController do
  use Web, :controller

  # action_fallback(Web.FallbackController)

  def create_token(conn, %{"username" => user_name, "password" => password}) do
    with {:ok, user, result} <- BillBored.Users.login(user_name, password),
         {:ok, %{flags: flags}} <- maybe_restrict_access(user) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(apply_flags(result, flags)))
    else
      {:error, _message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{message: "Can't login, invalid credentials or user doesn't exists"}))
    end
  end

  def create_token(conn, %{"email" => email, "password" => password}) do
    with {:ok, user, result} <- BillBored.Users.login_by_email(email, password),
         {:ok, %{flags: flags}} <- maybe_restrict_access(user) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(apply_flags(result, flags)))
    else
      {:error, _error_type} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{message: "Can't login, invalid credentials or user doesn't exists"}))
    end
  end

  defp apply_flags(result, %{"access" => "restricted"}) do
    Map.put(result, "access", "restricted")
  end

  defp apply_flags(result, _) do
    Map.put(result, "access", "granted")
  end

  defp maybe_restrict_access(%{flags: %{"access" => "granted"}} = user), do: {:ok, user}
  defp maybe_restrict_access(user) do
    case BillBored.KVEntries.AccessRestrictionPolicy.get() do
      %{value: %{enabled: false}} ->
        {:ok, user}

      _ ->
        BillBored.Users.replace_flags(user.id, %{
          "access" => "restricted",
          "restriction_reason" => "Thank you for your interest in the service. We will invite you in as soon as more room is available!"
        })
    end
  end
end
