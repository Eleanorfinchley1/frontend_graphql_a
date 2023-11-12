defmodule Web.MentorView do
  use Web, :view

  # Mentor Views
  def render("index.json", %{mentors: mentors}) do
    %{data: render_many(mentors, Web.MentorView, "mentor.json")}
  end

  def render("show.json", %{mentor: mentor}) do
    %{data: render_one(mentor, Web.MentorView, "mentor.json")}
  end

  def render("mentor.json", %{mentor: mentor}) do
    mentor_user = user_association(mentor.user)

    Map.merge(mentees_association(mentor.mentee), mentor_user)
  end

  def render("team.json", %{team: team}) do
    payload = %{
      "name" => "Team_#{team.username}",
      "members" => [team | team.mentees] |> Enum.map(fn user -> render_one(user, Web.UserView, "user.json", as: :user) end)
    }
    payload = if is_nil(team.semester_points) do
        payload
      else
        Map.put(payload, :semester_points, team.semester_points / 10)
      end
    payload = if is_nil(team.monthly_points) do
        payload
      else
        Map.put(payload, :monthly_points, team.monthly_points / 10)
      end
    payload = if is_nil(team.weekly_points) do
        payload
      else
        Map.put(payload, :weekly_points, team.weekly_points / 10)
      end
    payload = if is_nil(team.daily_points) do
        payload
      else
        Map.put(payload, :daily_points, team.daily_points / 10)
      end
    if is_nil(team.total_points) do
      payload
    else
      Map.put(payload, :total_points, team.total_points / 10)
    end
  end

  # Mentee Users
  def render("index.json", %{mentees: mentees}) do
    %{data: render_many(mentees, Web.MentorView, "mentee.json", as: :mentee)}
  end

  def render("show.json", %{mentee: mentee}) do
    %{data: render_one(mentee, Web.MentorView, "mentee.json", as: :mentee)}
  end

  def render("mentee.json", %{mentee: mentee}) do
    core = %{
      mentor_id: mentee.mentor_id,
      mentor_assigned: mentee.mentor_assigned
    }

    mentee_user = user_association(mentee.user)

    Map.merge(core, mentee_user)
  end

  def render("mentor_mentee.json", %{mentee: mentee}) do
    core = %{
      mentor_id: mentee.mentor_id,
      mentor_assigned: mentee.mentor_assigned
    }

    mentee_user = user_association(mentee.user)

    Map.merge(core, mentee_user)
  end

  defp mentees_association(nil), do: %{}

  defp mentees_association(mentees) do
    if Ecto.assoc_loaded?(mentees) do
      %{mentees: render_many(mentees, Web.MentorView, "mentee.json", as: :mentee)}
    else
      %{}
    end
  end

  defp user_association(nil), do: %{}

  defp user_association(user) do
    if Ecto.assoc_loaded?(user) do
      user_data = Web.UserView.render("custom_user.json", %{user: user})

      Map.merge(user_data, university_association(user.university))
    else
      %{}
    end
  end

  defp university_association(nil), do: %{}

  defp university_association(university) do
    if Ecto.assoc_loaded?(university) do
      %{university_name: university.name}
    else
      %{}
    end
  end

end
