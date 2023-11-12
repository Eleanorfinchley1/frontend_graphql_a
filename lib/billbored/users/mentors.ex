defmodule BillBored.Users.Mentors do

  alias BillBored.UserPoints
  alias BillBored.Users.Mentor
  alias BillBored.Users.Mentee

  import Ecto.Query

  def create(params) do
    %Mentor{}
    |> Mentor.changeset(params)
    |> Repo.insert()
  end

  def list do
    query = from m in Mentor, preload: :user
    Repo.all(query)
  end

  def delete(id) do
    with %Mentor{} = mentor <- get_by_id(id),
      {:ok, mentor} <- Repo.delete(mentor) do
        {:ok, mentor}
    end
  end

  def get_by_id(id) do
    query = from m in Mentor, preload: [mentee: [user: :university], user: [:interests_interest, :university]]

    Repo.get(query, id)
  end

  @doc """
  Algorithm:
    1. Get all mentors.
    2. Order by the length of mentees they have.
    3. Return the mentor with the minimum mentees

  Returns the mentor id which will be assigned
  """
  @spec get_assigned_mentor(for: pos_integer) :: integer()
  def get_assigned_mentor(for: university_id) do
    mentors = Repo.all(from m in Mentor,
      inner_join: u in assoc(m, :user),
      where: u.university_id == ^university_id,
      preload: :mentee
    )

    if length(mentors) > 0 do
      {mentor_id, _mentee_length} =
        mentors
        |> Enum.map(fn mentor -> {mentor.mentor_id, length(mentor.mentee)} end)
        |> Enum.sort_by(fn {_mentor_id, len} -> len end)
        |> Enum.at(0)

      mentor_id
    else
      nil
    end
  end

  def list_mentee_ids(mentor_id) when is_integer(mentor_id) do
    Mentee
    |> where([m], m.mentor_id == ^mentor_id)
    |> select([m], m.user_id)
    |> Repo.all()
  end

  def list_mentee_ids(mentor_ids) when is_list(mentor_ids) do
    Mentee
    |> where([m], m.mentor_id in ^mentor_ids)
    |> select([m], m.user_id)
    |> Repo.all()
  end

  def query_general_points_between(period \\ nil) do
    query1 = from m in Mentor, select: %{mentor_id: m.mentor_id, user_id: m.mentor_id}
    query2 = from m in Mentee, select: %{mentor_id: m.mentor_id, user_id: m.user_id}
    query3 = UserPoints.query_general_points_between(period)
    subquery(union(query1, ^query2))
    |> join(:left, [m], upa in subquery(query3), on: upa.user_id == m.user_id)
    |> group_by([m], m.mentor_id)
    |> select([m, upa], %{
      user_id: m.mentor_id,
      points: fragment("COALESCE(SUM(ABS(?))::integer, 0)", upa.points),
      p_type: "general"
    })
  end
end
