defmodule BillBored.Admins do
  import Ecto.Query
  import Bcrypt, only: [verify_pass: 2]
  alias BillBored.Admin

  @initial_password "P@ssW0rd"
  # @default_page_size 15

  def create(attrs) do
    attrs = Map.put(attrs, :password, @initial_password)
    %Admin{}
    |> Admin.create_changeset(attrs)
    |> Repo.insert()
  end

  def send_email_invitation(admin) do
    alias Web.Router.Helpers, as: Routes

    token = Admin.AuthTokens.generate(admin)
    invitation_url =
      Routes.torch_api_admin_url(Web.Endpoint, :accept_invitation, token: token)

    Mail.email_invitation(admin.email, %{url: invitation_url})
  end

  def send_email_reset_account(admin, password) do
    login_page_url = Application.get_all_env(:billbored)[:torch_login_page_url]

    Mail.email_reset_account(admin.email, %{url: login_page_url, password: password, username: admin.username})
  end

  def reset_account(admin) do
    rand_password = :crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)
    with {:ok, admin} <- (admin
      |> Admin.update_changeset(%{status: "accepted", password: rand_password})
      |> Repo.update()) do
        send_email_reset_account(admin, rand_password)
        {:ok, admin}
    end
  end

  def ban_account(admin) do
    admin
    |> Admin.update_changeset(%{status: "banned"})
    |> Repo.update()
  end

  defp get_admin(username: username) do
    case get_by_username(username) do
      %Admin{} = admin ->
        {:ok, admin}

      _ ->
        {:error, :admin_not_found}
    end
  end

  defp get_admin(email: email) do
    case get_by_email(email) do
      %Admin{} = admin ->
        {:ok, admin}

      _ ->
        {:error, :admin_not_found}
    end
  end

  def registration_status(%Admin{status: status}) do
    case status do
      "pending" -> :invitation_accept_required
      "expired" -> :invitation_required
      "accepted" -> :password_reset_required
      "enabled" -> :completed
      "banned" -> :banned
    end
  end

  def signable_admin?(%Admin{status: status}), do: status == "enabled" or status == "accepted"

  defp sign_in_admin(%Admin{password: actual_password} = admin, attempted_password) do
    with true <- verify_pass(attempted_password, actual_password),
         true <- signable_admin?(admin),
         token <- Admin.AuthTokens.generate(admin) do
      {:ok, %{
        token: token,
        registration_status: registration_status(admin)
      }}
    else
      _ ->
        {:error, :admin_not_found_or_banned}
    end
  end

  def change_password(%Admin{password: actual_password} = admin, old_pwd, new_pwd) do
    with true <- verify_pass(old_pwd, actual_password) do
      admin
      |> Admin.update_changeset(%{password: new_pwd})
      |> Repo.update()
    else
      _ ->
        {:error, :incorrect_password}
    end
  end

  def update(%Admin{} = admin, attrs) do
    admin
    |> Admin.update_changeset(attrs)
    |> Repo.update()
  end

  def get_by_id(id) do
    Admin
    |> where([u], u.id == ^id)
    |> preload([:roles, :university])
    |> Repo.one()
  end

  def get_by_username(username) do
    Admin
    |> where([u], fragment("lower(?)", u.username) == ^String.downcase(username))
    |> first()
    |> Repo.one()
  end

  def get_by_email(email) do
    Admin
    |> where([u], u.email == ^email)
    |> first()
    |> Repo.one()
  end

  def login(username, password) do
    with {:ok, admin} <- get_admin(username: username),
         {:ok, result} <- sign_in_admin(admin, password) do
      {:ok, admin, result}
    end
  end

  def login_by_email(email, password) do
    with {:ok, admin} <- get_admin(email: email),
         {:ok, result} <- sign_in_admin(admin, password) do
      {:ok, admin, result}
    end
  end

  def get_by_token(token) do
    with {:ok, %{id: admin_id, status: status, hash: hash}} <- Admin.AuthTokens.verify_payload(token) do
      admin = Admin
        |> where([u], u.id == ^admin_id and u.status == ^status and u.password == ^hash)
        |> first()
        |> Repo.one()

      if is_nil(admin) do
        {:error, :old_token}
      else
        {:ok, admin}
      end
    end
  end

  def paginate(params) do
    # page = params[:page] || 1
    # page_size = params[:page_size] || @default_page_size
    sort_field = params[:sort_field] || "id"
    sort_direction = params[:sort_direction] || "asc"
    keyword = params[:keyword] || ""
    filter = params[:filter] || ""

    query = Admin
      |> order_by([{^String.to_atom(sort_direction), ^String.to_atom(sort_field)}])
      |> preload([:university])

    query = if keyword == "" do
      query
    else
      keyword = "%#{keyword}%"
      query
      |> where([a], like(a.username, ^keyword) or like(a.email, ^keyword) or like(a.first_name, ^keyword) or like(a.last_name, ^keyword))
    end

    query = if filter == "all" or filter == "" do
      query
    else
      query
      |> where([a], a.status == ^filter)
    end

    page = Repo.paginate(query, params)

    %{
      entries: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries,
      sort_field: sort_field,
      sort_direction: sort_direction,
      keyword: keyword,
      filter: filter
    }
  end

  def assign_roles(admin_id, role_ids) do
    Admin.Roles.delete_all_by_admin_id(admin_id)
    role_ids
    |> Enum.reduce({:ok, :success}, fn role_id, result ->
      case Admin.Roles.create(%{
        admin_id: admin_id,
        role_id: role_id
      }) do
        {:ok, _admin_role} ->
          result
        err ->
          err
      end
    end)
  end
end
