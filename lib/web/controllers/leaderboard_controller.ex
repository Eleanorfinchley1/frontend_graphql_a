defmodule Web.LeaderboardController do
  use Web, :controller

  alias BillBored.Leaderboard

  action_fallback Web.FallbackController

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def show(conn, _, user_id) do
    case Leaderboard.user_points_cache(user_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{msg: "User NOT Exist!"}))
      user ->
        team = if is_nil(user.mentor || user.mentee) do
          nil
        else
          mentor_id = (user.mentor || user.mentee).mentor_id
          Leaderboard.team_points_cache(mentor_id)
        end

        university_id = user.university_id || (team || %{university_id: 0}).university_id || 0

        ahead_user = Leaderboard.ahead_user_points_cache(user.semester_points, university_id)
        behind_user = Leaderboard.behind_user_points_cache(user.semester_points, university_id)

        ahead_team = if not is_nil(team) do
          Leaderboard.ahead_team_points_cache(team.semester_points, university_id)
        end
        behind_team = if not is_nil(team) do
          Leaderboard.behind_team_points_cache(team.semester_points, university_id)
        end

        university = Leaderboard.university_points_cache(university_id)
        ahead_university = if not is_nil(university) do
          Leaderboard.ahead_university_points_cache(university.semester_points, university_id)
        end
        behind_university = if not is_nil(university) do
          Leaderboard.behind_university_points_cache(university.semester_points, university_id)
        end

        render(
          conn,
          "show.json",
          user: user,
          competitors: [ahead_user, user, behind_user],
          teams: [ahead_team, team, behind_team],
          universities: [ahead_university, university, behind_university]
        )
    end
  end
end
