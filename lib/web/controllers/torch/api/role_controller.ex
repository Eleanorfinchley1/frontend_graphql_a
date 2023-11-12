defmodule Web.Torch.API.AdminRoleController do
  use Web, :controller
  alias BillBored.AdminRoles
  plug Web.Plugs.TorchCheckPermissions, required_permission: [
    create: "role:create",
    update: "role:update",
    delete: "role:delete",
    show: "role:show",
    index: "role:list",
    all: "role:assign"
  ]

  @index_params [
    {"page", :page, false, :integer},
    {"page_size", :page_size, false, :integer},
    {"sort_direction", :sort_direction, false, :string},
    {"sort_field", :sort_field, false, :string},
    {"keyword", :keyword, false, :string},
    {"filter", :filter, false, :string}
  ]
  def index(%Plug.Conn{} = conn, params) do
    {:ok, params} = validate_params(@index_params, params)

    conn
    |> render("index.json", page: AdminRoles.paginate(params))
  end

  def create(%Plug.Conn{} = conn, params) do
    case AdminRoles.create(params) do
      {:ok, role} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(role))
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

  def update(%Plug.Conn{} = conn, %{"id" => id} = params) do
    case AdminRoles.get_by_id(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Role not exists."}))
      role ->
        case AdminRoles.update(role, params) do
          {:ok, role} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(role))
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

  def delete(%Plug.Conn{} = conn, %{"id" => id}) do
    case AdminRoles.delete_by_id(id) do
      {1, _} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{message: "Deleted successfully"}))
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Role not exists."}))
    end
  end

  def show(%Plug.Conn{} = conn, %{"id" => id}) do
    case AdminRoles.get_by_id(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Role not exists."}))
      role ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(role))
    end
  end

  def all(%Plug.Conn{} = conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(AdminRoles.all()))
  end
end
