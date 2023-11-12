defmodule Web.MentorController do
  use Web, :controller

  action_fallback Web.FallbackController

  alias BillBored.Users.Mentors
  alias BillBored.Users.Mentees

  alias BillBored.Users
  alias BillBored.User

  # Mentor CRUD controllers
  def list(conn, _params) do
    mentors = Mentors.list()
    render(conn, "index.json", mentors: mentors)
  end

  def get(conn, %{"id" => id}) do
    mentor = Mentors.get_by_id(id)
    render(conn, "show.json", mentor: mentor)
  end

  def create(conn, %{"user_id" => user_id}) do
    with {:ok, _mentor} <- Mentors.create(%{"mentor_id" => user_id}) do
      send_resp(conn, :ok, [])
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, _mentor} <- Mentors.delete(id) do
      send_resp(conn, :ok, [])
    end
  end

  # Mentor-Mentee CRUD controllers
  def assign_mentor(conn, %{"user_id" => user_id}) do
    with %User{} = user <- Users.get!(user_id),
        mentor_id <- Mentors.get_assigned_mentor(for: user.university_id),
        {:ok, mentee} <- Mentees.create(%{"user_id" => user_id, "mentor_id" => mentor_id}) do
          render(conn, "show.json", mentee: mentee)
    end
  end

  # Mentee controllers
  def list_mentees(conn, _params) do
    mentees = Mentees.list()
    render(conn, "index.json", mentees: mentees)
  end

  def get_mentee(conn, %{"id" => id}) do
    mentee   = Mentees.get_by_id!(id)

    render(conn, "show.json", mentee: mentee)
  end
end
