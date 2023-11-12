defmodule BillBored.AdminRoles do
  import Ecto.Query
  alias BillBored.AdminRole

  def paginate(params) do
    # page = params[:page] || 1
    # page_size = params[:page_size] || @default_page_size
    sort_field = params[:sort_field] || "id"
    sort_direction = params[:sort_direction] || "asc"
    keyword = params[:keyword] || ""
    filter = params[:filter] || ""

    query = AdminRole
      |> order_by([{^String.to_atom(sort_direction), ^String.to_atom(sort_field)}])

    query = if keyword == "" do
      query
    else
      keyword = "%#{keyword}%"
      query
      |> where([a], like(a.label, ^keyword))
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

  def get_by_id(id) do
    AdminRole
    |> where(id: ^id)
    |> limit(1)
    |> Repo.one()
  end

  def create(params) do
    %AdminRole{}
    |> AdminRole.create_changeset(params)
    |> Repo.insert()
  end

  def update(role, attrs) do
    role
    |> AdminRole.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_by_id(id) do
    AdminRole
    |> where(id: ^id)
    |> Repo.delete_all()
  end

  def delete(%AdminRole{} = role), do: Repo.delete(role)

  def all() do
    AdminRole
    |> Repo.all()
  end
end
