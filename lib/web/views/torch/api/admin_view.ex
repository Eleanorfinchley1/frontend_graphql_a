defmodule Web.Torch.API.AdminView do
  use Web, :view

  def render("show.json", %{admin: admin}) do
    payload = %{
      id: admin.id,
      username: admin.username,
      email: admin.email,
      first_name: admin.first_name,
      last_name: admin.last_name,
      status: admin.status,
      university_id: admin.university_id,
      university: admin.university,
      inserted_at: admin.inserted_at,
      updated_at: admin.updated_at
    }
    if Ecto.assoc_loaded?(admin.roles) do
      Map.put(payload, :roles, admin.roles)
    else
      payload
    end
  end

  def render("min.json", %{admin: admin}) do
    %{
      id: admin.id,
      username: admin.username,
      email: admin.email,
      first_name: admin.first_name,
      last_name: admin.last_name,
      avatar: nil,
      avatar_thumbnail: nil,
      type: "admin"
    }
  end

  def render("index.json", %{page: page}) do
    %{
      entries: page.entries |> Enum.map(fn item -> render("show.json", admin: item) end),
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
