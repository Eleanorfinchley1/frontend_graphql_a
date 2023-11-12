defmodule BillBored.Universities do
  import Ecto.Query
  alias BillBored.University
  alias BillBored.User
  alias BillBored.UserPoints

  @doc "Get all"
  def list do
    Repo.all(University)
  end

  @doc "Get by allowance"
  def get_by_allowance(allowed) do
    University
    |> where([u], u.allowed == ^allowed)
    |> Repo.all()
  end

  def get_by_id(id) do
    University
    |> where([u], u.id == ^id)
    |> Repo.one!()
  end

  @doc "Create a university record"
  def create(attrs) do
    %University{}
    |> University.changeset(attrs)
    |> Repo.insert()
  end

  def delete(id) do
    with university <- get_by_id(id) do
      Repo.delete!(university)
    end
  end

  def query_general_points_between(period \\ nil) do
    query3 = UserPoints.query_general_points_between(period)
    University
    |> join(:left, [un], u in User, on: u.university_id == un.id and is_nil(u.event_provider) and u.banned? == false and u.deleted? == false)
    |> join(:left, [un, u], upa in subquery(query3), on: upa.user_id == u.id)
    |> group_by([un], un.id)
    |> select([un, _u, upa], %{
      university_id: un.id,
      points: fragment("COALESCE(SUM(ABS(?))::integer, 0)", upa.points),
      p_type: "general"
    })
  end
end
