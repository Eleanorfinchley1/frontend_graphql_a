defmodule Web.Torch.API.AdminRoleView do
  use Web, :view

  def render("show.json", %{role: role}) do
    %{
      id: role.id,
      label: role.label,
      permissions: role.permissions
    }
  end

  def render("index.json", %{page: page}) do
    %{
      entries: page.entries |> Enum.map(fn item -> render("show.json", role: item) end),
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries,
      sort_field: page.sort_field,
      sort_direction: page.sort_direction,
      keyword: page.keyword,
      filter: page.filter
    }
  end
end
