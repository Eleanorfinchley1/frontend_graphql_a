defmodule BillBored.Users.Mentees do
  alias BillBored.Users.Mentee

  import Ecto.Query

  def create(params) do
    %Mentee{}
    |> Mentee.changeset(params)
    |> Repo.insert()
  end

  def list do
    Repo.all(Mentee)
  end

  def delete(id) do
    with mentee <- get_by_id!(id),
      {:ok, mentee} <- Repo.delete(mentee) do
        {:ok, mentee}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  def get_by_id!(id) do
    query = from m in Mentee, where: m.user_id == ^id

    Repo.one(query)
  end

end
