defmodule BillBored.Admin.Roles do
  import Ecto.Query
  alias BillBored.Admin.Role

  def get_permissions_by_admin_id(admin_id) do
    Role
    |> where([r], r.admin_id == ^admin_id)
    |> join(:inner, [r], p in assoc(r, :role))
    |> select([_r, p], p.permissions)
    |> Repo.all()
  end

  def create(attrs) do
    %Role{}
    |> Role.create_changeset(attrs)
    |> Repo.insert()
  end

  def delete_all_by_admin_id(id) do
    Role
    |> where(admin_id: ^id)
    |> Repo.delete_all()
  end
end
