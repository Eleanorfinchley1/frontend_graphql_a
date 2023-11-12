defmodule Web.Torch.API.AdminController do
  use Web, :controller
  alias BillBored.Admins
  plug Web.Plugs.TorchCheckPermissions, required_permission: [
    register_and_invite: "admin:create",
    reset_account: "admin:update",
    ban_account: "admin:update",
    update_account: "admin:update",
    show_account: "admin:show",
    assign_roles: "role:assign",
    index: "admin:list"
  ]

  def auth_token(conn, %{"username" => user_name, "password" => password}) do
    with {:ok, _admin, result} <- Admins.login(user_name, password) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(result))
    else
      {:error, _message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{message: "Can't login, invalid credentials or the banned admin"}))
    end
  end

  def auth_token(conn, %{"email" => email, "password" => password}) do
    with {:ok, _admin, result} <- Admins.login_by_email(email, password) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(result))
    else
      {:error, _error_type} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{message: "Can't login, invalid credentials or the banned admin"}))
    end
  end

  def verify_token(conn, %{"token" => token}) do
    {result, reason} = BillBored.Admin.AuthTokens.verify_payload(token)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{result: result, reason: reason}))
  end

  def register_and_invite(conn, %{"username" => username, "email" => email}) do
    case Admins.create(%{
      username: username,
      email: email
    }) do
      {:ok, admin} ->
        Admins.send_email_invitation(admin)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(admin))
      {:error, %{errors: [{key, {reason, _}} | _]}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "#{key} #{reason}"}))
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{message: "Something went wrong!"}))
    end
  end

  def accept_invitation(conn, %{"token" => token}) do
    case Admins.get_by_token(token) do
      {:ok, admin} ->
        Admins.reset_account(admin)
        login_page_url = Application.get_all_env(:billbored)[:torch_login_page_url]
        redirect(conn, external: login_page_url)

      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:forbidden, Jason.encode!(%{message: Atom.to_string(reason)}))

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:forbidden, Jason.encode!(%{message: "Invalid token"}))
    end
  end

  def reset_account(conn, %{"id" => id}) do
    case Admins.get_by_id(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Account not exists."}))
      admin ->
        {:ok, admin} = Admins.reset_account(admin)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(admin))
    end
  end

  def ban_account(conn, %{"id" => id}) do
    case Admins.get_by_id(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Account not exists."}))
      admin ->
        {:ok, admin} = Admins.ban_account(admin)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(admin))
    end
  end

  def change_password(%{assigns: %{admin: admin}} = conn, %{"old_password" => old_pwd, "new_password" => new_pwd}) do
    case Admins.change_password(admin, old_pwd, new_pwd) do
      {:ok, admin} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(admin))
      {:error, %{errors: [{key, {reason, _}} | _]}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "#{key} #{reason}"}))
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Incorrect Password"}))
    end
  end

  def update(%{assigns: %{admin: admin}} = conn, attrs) do
    case Admins.update(admin, attrs) do
      {:ok, admin} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(admin))
      {:error, %{errors: [{key, {reason, _}} | _]}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "#{key} #{reason}"}))
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{message: "Something went wrong!"}))
    end
  end

  def update_account(conn, %{"id" => id} = attrs) do
    case Admins.get_by_id(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Account not exists."}))
      admin ->
        case Admins.update(admin, attrs) do
          {:ok, admin} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(admin))
          {:error, %{errors: [{key, {reason, _}} | _]}} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{message: "#{key} #{reason}"}))
          _ ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{message: "Something went wrong!"}))
        end
    end
  end

  def show(%{assigns: %{admin: admin}} = conn, _attrs) do
    case Admins.get_by_id(admin.id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Account not exists."}))
      admin ->
        conn
        |> render("show.json", admin: admin)
    end
  end

  def show_account(conn, %{"id" => id}) do
    case Admins.get_by_id(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Account not exists."}))
      admin ->
        conn
        |> render("show.json", admin: admin)
    end
  end

  def assign_roles(conn, %{"id" => id, "roles" => roles} = params) do
    case Admins.assign_roles(id, roles) do
      {:ok, _} ->
        show_account(conn, params)
      {:error, %{errors: [{key, {reason, _}} | _]}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "#{key} #{reason}"}))
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{message: "Something went wrong!"}))
    end
  end

  @index_params [
    {"page", :page, false, :integer},
    {"page_size", :page_size, false, :integer},
    {"sort_direction", :sort_direction, false, :string},
    {"sort_field", :sort_field, false, :string},
    {"keyword", :keyword, false, :string},
    {"filter", :filter, false, :string}
  ]
  def index(conn, params) do
    {:ok, params} = validate_params(@index_params, params)

    conn
    |> render("index.json", page: Admins.paginate(params))
  end
end
