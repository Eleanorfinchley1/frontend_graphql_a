alias BillBored.{User, Users, User.Membership, User.Memberships}

import_if_available(Ecto)
import_if_available(Ecto.Changeset)
import_if_available(Ecto.Query)

defmodule H do
  def get_all(model), do: Repo.all(model)

  def get(model, id), do: Repo.get(model, id)

  def update(model, id, attrs \\ %{}) do
    Repo.update(Ecto.Changeset.change(Repo.get(model, id), attrs))
  end

  def delete(model, id), do: Repo.delete(get(model, id))
end

try do
  Code.require_file(".iex.local.exs")
rescue
  e in Code.LoadError -> e
end
