defmodule Web.Torch.API.InterestController do
  use Web, :controller
  import BillBored.Helpers, only: [humanize_errors: 1]
  alias BillBored.Interests

  plug Web.Plugs.TorchCheckPermissions, required_permission: [
    create: "interest:create",
    update: "interest:update",
    delete: "interest:delete",
    show: "interest:show",
    index: "interest:list"
  ]

  def list(conn, _opts) do
    rendered_json = Web.InterestView.render("list.json", conn: conn, data: Interests.list())
    json(conn, rendered_json)
  end

  @index_params [
    {"page", :page, false, :integer},
    {"page_size", :page_size, false, :integer},
    {"sort_direction", :sort_direction, false, :string},
    {"sort_field", :sort_field, false, :string},
    {"keyword", :keyword, false, :string},
    {"filter_disabled", :filter_disabled, false, :string}
  ]
  def index(conn, params) do
    {:ok, params} = validate_params(@index_params, params)

    page = Interests.paginate(params)
    rendered_post = Web.InterestView.render("index.json", conn: conn, data: page)
    json(conn, rendered_post)
  end

  def show(conn, %{"id" => interest_id}) do
    case Interests.get!(interest_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Interest not exists."}))
      interest ->
        rendered_post = Web.InterestView.render("show.json", interest: interest)
        json(conn, rendered_post)
    end
  end

  def create(conn, params) do
    case Interests.create(params) do
      {:ok, interest} ->
        rendered_post = Web.InterestView.render("show.json", interest: interest)
        json(conn, %{
          success: true,
          result: rendered_post
        })
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{success: false, reason: humanize_errors(reason)})
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{success: false, message: "Something went wrong!"}))
    end
  end

  def update(conn, %{"id" => interest_id} = params) do
    case Interests.get!(interest_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{message: "Interest not exists."}))
      interest ->
        case Interests.update(interest, params) do
          {:ok, interest} ->
            rendered_post = Web.InterestView.render("show.json", interest: interest)
            json(conn, %{
              success: true,
              result: rendered_post
            })
          {:error, reason} ->
            conn
            |> put_status(400)
            |> json(%{success: false, reason: humanize_errors(reason)})
          _ ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{success: false, message: "Something went wrong!"}))
        end
    end
  end

  def delete(conn, %{"id" => interest_id}) do
    case Interests.delete(interest_id) do
      {:ok, interest} ->
        send_resp(conn, 204, [])

      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{success: false, reason: humanize_errors(reason)})

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{success: false, message: "Interest not exists."}))
    end
  end
end
