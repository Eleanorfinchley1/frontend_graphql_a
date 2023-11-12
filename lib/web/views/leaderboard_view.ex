defmodule Web.LeaderboardView do
  use Web, :view

  def render("show.json", %{
    user: me,
    competitors: competitors,
    teams: teams,
    universities: universities
  }) do
    %{
      "user" => render_one(me, Web.UserView, "user.json", as: :user),
      "competitors" => competitors
        |> Enum.filter(fn x -> x != nil end)
        |> Enum.map(fn user -> render_one(user, Web.UserView, "user.json", as: :user) end),
      "teams" => teams
        |> Enum.filter(fn x -> x != nil end)
        |> Enum.map(fn team -> render_one(team, Web.MentorView, "team.json", as: :team) end),
      "universities" => universities
        |> Enum.filter(fn x -> x != nil end)
        |> Enum.map(fn university -> render_one(university, Web.UniversityView, "university_points.json", as: :university) end)
    }
  end
end
