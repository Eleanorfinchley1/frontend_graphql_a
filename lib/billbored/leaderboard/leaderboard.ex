defmodule BillBored.Leaderboard do
  @moduledoc ""
  import Ecto.Query
  import BillBored.ServiceRegistry, only: [service: 1]

  alias BillBored.Period

  alias BillBored.University
  alias BillBored.Universities
  alias BillBored.User
  # alias BillBored.UserPoint
  alias BillBored.UserPoints
  # alias BillBored.Chat.Message, as: ChatMessage
  # alias BillBored.Chat.Room.DropchatStream
  # alias BillBored.Chat.Room.DropchatStream.Reaction, as: DropchatStreamReaction
  # alias BillBored.Chat.Room.DropchatStream.Speaker, as: DropchatStreamSpeaker
  # alias BillBored.Livestream
  # alias BillBored.Livestream.Comment, as: LivestreamComment
  # alias BillBored.Livestream.Comment.Vote, as: LivestreamCommentVote
  # alias BillBored.Livestream.View, as: LivestreamView
  # alias BillBored.Livestream.Vote, as: LivestreamVote
  # alias BillBored.Users.Mentor
  # alias BillBored.Users.Mentee
  alias BillBored.Users.Mentors

  def user_score(nil), do: %{id: 0, semester_points: 0, monthly_points: 0, weekly_points: 0, daily_points: 0}
  def user_score(0), do: %{id: 0, semester_points: 0, monthly_points: 0, weekly_points: 0, daily_points: 0}

  def user_score(user_id) do
    semester_query = Period.semester |> UserPoints.query_general_points_between
    month_query = Period.month |> UserPoints.query_general_points_between
    week_query = Period.week |> UserPoints.query_general_points_between
    today_query = Period.today |> UserPoints.query_general_points_between

    User
    |> where([u], u.id == ^user_id)
    |> join(:left, [u], upa in subquery(semester_query), on: upa.user_id == u.id, as: :semester)
    |> join(:left, [u], upa in subquery(month_query), on: upa.user_id == u.id, as: :month)
    |> join(:left, [u], upa in subquery(week_query), on: upa.user_id == u.id, as: :week)
    |> join(:left, [u], upa in subquery(today_query), on: upa.user_id == u.id, as: :today)
    |> select_merge([semester: semester, month: month, week: week, today: today], %{
      semester_points: fragment("COALESCE(?, 0)", semester.points),
      monthly_points: fragment("COALESCE(?, 0)", month.points),
      weekly_points: fragment("COALESCE(?, 0)", week.points),
      daily_points: fragment("COALESCE(?, 0)", today.points)
    })
    |> preload([:mentor, :mentee])
    |> Repo.one()
  end

  def team_score(nil), do: %{id: 0, semester_points: 0, monthly_points: 0, weekly_points: 0, daily_points: 0}
  def team_score(0), do: %{id: 0, semester_points: 0, monthly_points: 0, weekly_points: 0, daily_points: 0}

  def team_score(mentor_id) do
    semester_query = Period.semester |> Mentors.query_general_points_between
    month_query = Period.month |> Mentors.query_general_points_between
    week_query = Period.week |> Mentors.query_general_points_between
    today_query = Period.today |> Mentors.query_general_points_between

    User
    |> where([u], u.id == ^mentor_id)
    |> join(:left, [u], upa in subquery(semester_query), on: upa.user_id == u.id, as: :semester)
    |> join(:left, [u], upa in subquery(month_query), on: upa.user_id == u.id, as: :month)
    |> join(:left, [u], upa in subquery(week_query), on: upa.user_id == u.id, as: :week)
    |> join(:left, [u], upa in subquery(today_query), on: upa.user_id == u.id, as: :today)
    |> select_merge([
      semester: semester,
      month: month,
      week: week,
      today: today
    ], %{
      semester_points: fragment("COALESCE(?, 0)", semester.points),
      monthly_points: fragment("COALESCE(?, 0)", month.points),
      weekly_points: fragment("COALESCE(?, 0)", week.points),
      daily_points: fragment("COALESCE(?, 0)", today.points)
    })
    |> Repo.one()
  end

  def university_score(nil), do: %{id: 0, semester_points: 0, monthly_points: 0, weekly_points: 0, daily_points: 0}
  def university_score(0), do: %{id: 0, semester_points: 0, monthly_points: 0, weekly_points: 0, daily_points: 0}

  def university_score(university_id) do
    semester_query = Period.semester |> Universities.query_general_points_between
    month_query = Period.month |> Universities.query_general_points_between
    week_query = Period.week |> Universities.query_general_points_between
    today_query = Period.today |> Universities.query_general_points_between

    University
    |> where([u], u.id == ^university_id)
    |> join(:left, [u], upa in subquery(semester_query), on: upa.university_id == u.id, as: :semester)
    |> join(:left, [u], upa in subquery(month_query), on: upa.university_id == u.id, as: :month)
    |> join(:left, [u], upa in subquery(week_query), on: upa.university_id == u.id, as: :week)
    |> join(:left, [u], upa in subquery(today_query), on: upa.university_id == u.id, as: :today)
    |> select_merge([
      semester: semester,
      month: month,
      week: week,
      today: today
    ], %{
      semester_points: fragment("COALESCE(?, 0)", semester.points),
      monthly_points: fragment("COALESCE(?, 0)", month.points),
      weekly_points: fragment("COALESCE(?, 0)", week.points),
      daily_points: fragment("COALESCE(?, 0)", today.points)
    })
    |> Repo.one()
  end

  defp date_key({_, %DateTime{} = datetime}) do
    datetime
    |> DateTime.to_date()
    |> Date.to_string()
  end

  defp semester_key, do: Period.semester |> date_key

  defp user_semester_key, do: "lb:user:semester:#{semester_key()}"

  defp team_semester_key, do: "lb:team:semester:#{semester_key()}"

  defp university_semester_key, do: "lb:university:semester:#{semester_key()}"

  defp monthly_key, do: Period.month |> date_key

  defp user_monthly_key, do: "lb:user:monthly:#{monthly_key()}"

  defp team_monthly_key, do: "lb:team:monthly:#{monthly_key()}"

  defp university_monthly_key, do: "lb:university:monthly:#{monthly_key()}"

  defp weekly_key, do: Period.week |> date_key

  defp user_weekly_key, do: "lb:user:weekly:#{weekly_key()}"

  defp team_weekly_key, do: "lb:team:weekly:#{weekly_key()}"

  defp university_weekly_key, do: "lb:university:weekly:#{weekly_key()}"

  defp daily_key, do: Period.today |> date_key

  defp user_daily_key, do: "lb:user:daily:#{daily_key()}"

  defp team_daily_key, do: "lb:team:daily:#{daily_key()}"

  defp university_daily_key, do: "lb:university:daily:#{daily_key()}"

  defp key_expire({_, %DateTime{} = datetime}), do: DateTime.diff(datetime, DateTime.utc_now())

  defp semester_expire, do: Period.semester |> key_expire

  defp monthly_expire, do: Period.month |> key_expire

  defp weekly_expire, do: Period.week |> key_expire

  defp daily_expire, do: Period.today |> key_expire

  def start_task_to_update_leaderboard(audit) do
    if Mix.env() != :test do
      Task.async(fn ->

        {micro_secs, user} = :timer.tc(__MODULE__, :user_score, [audit.user_id])
        IO.inspect("Load User Score: Time-Consuming #{micro_secs / 1000000} seconds")

        team_id = (user.mentor || user.mentee || %{mentor_id: 0}).mentor_id || 0
        {micro_secs, team} = :timer.tc(__MODULE__, :team_score, [team_id])
        IO.inspect("Load Team Score: Time-Consuming #{micro_secs / 1000000} seconds")

        university_id = user.university_id || (team || %{university_id: 0}).university_id || 0
        {micro_secs, university} = :timer.tc(__MODULE__, :university_score, [university_id])
        IO.inspect("Load University Score: Time-Consuming #{micro_secs / 1000000} seconds")

        commands = [
          ["ZADD", user_semester_key(), to_string(user.semester_points), to_string(user.id)],
          ["EXPIRE", user_semester_key(), semester_expire()],
          ["ZADD", team_semester_key(), to_string(team.semester_points), to_string(team.id)],
          ["EXPIRE", team_semester_key(), semester_expire()],
          ["ZADD", university_semester_key(), to_string(university.semester_points), to_string(university.id)],
          ["EXPIRE", university_semester_key(), semester_expire()],
          ["ZADD", user_monthly_key(), to_string(user.monthly_points), to_string(user.id)],
          ["EXPIRE", user_monthly_key(), monthly_expire()],
          ["ZADD", team_monthly_key(), to_string(team.monthly_points), to_string(team.id)],
          ["EXPIRE", team_monthly_key(), monthly_expire()],
          ["ZADD", university_monthly_key(), to_string(university.monthly_points), to_string(university.id)],
          ["EXPIRE", university_monthly_key(), monthly_expire()],
          ["ZADD", user_weekly_key(), to_string(user.weekly_points), to_string(user.id)],
          ["EXPIRE", user_weekly_key(), weekly_expire()],
          ["ZADD", team_weekly_key(), to_string(team.weekly_points), to_string(team.id)],
          ["EXPIRE", team_weekly_key(), weekly_expire()],
          ["ZADD", university_weekly_key(), to_string(university.weekly_points), to_string(university.id)],
          ["EXPIRE", university_weekly_key(), weekly_expire()],
          ["ZADD", user_daily_key(), to_string(user.daily_points), to_string(user.id)],
          ["EXPIRE", user_daily_key(), daily_expire()],
          ["ZADD", team_daily_key(), to_string(team.daily_points), to_string(team.id)],
          ["EXPIRE", team_daily_key(), daily_expire()],
          ["ZADD", university_daily_key(), to_string(university.daily_points), to_string(university.id)],
          ["EXPIRE", university_daily_key(), daily_expire()],
          ["SADD", "university:#{university_id}:members", to_string(user.id), to_string(team.id)]
        ]

        {micro_secs, _} = :timer.tc(service(BillBored.Redix), :pipeline, [commands])
        IO.inspect("Update Leaderboard Data: Time-Consuming #{micro_secs / 1000000} seconds")

        ## Notifications
        # For users
        before_change = user.semester_points - abs(audit.points) + 1
        after_change = user.semester_points - 1
        {micro_secs, _} = :timer.tc(service(BillBored.Redix), :command, [["ZDIFFSTORE", "#{user_semester_key()}:#{university_id}", "2", user_semester_key(), "university:#{university_id}:members"]])
        IO.inspect("Load Other Uni User Data: Time-Consuming #{micro_secs / 1000000} seconds")
        {:ok, ids} = service(BillBored.Redix).command(["ZRANGEBYSCORE", "#{user_semester_key()}:#{university_id}", "#{before_change}", "#{after_change}"])
        if length(ids) > 0 do
          ids = Enum.map(ids, fn id -> String.to_integer(id) end)
          receivers = User
            |> where([u], u.id in ^ids)
            |> preload([:devices])
            |> Repo.all()
          Notifications.process_user_passed_leaderboard(user, receivers)
        end

        # For teams
        before_change = team.semester_points - abs(audit.points) + 1
        after_change = team.semester_points - 1
        {micro_secs, _} = :timer.tc(service(BillBored.Redix), :command, [["ZDIFFSTORE", "#{team_semester_key()}:#{university_id}", "2", team_semester_key(), "university:#{university_id}:members"]])
        IO.inspect("Load Other Uni Team Data: Time-Consuming #{micro_secs / 1000000} seconds")
        {:ok, ids} = service(BillBored.Redix).command(["ZRANGEBYSCORE", "#{team_semester_key()}:#{university_id}", "#{before_change}", "#{after_change}"])
        if length(ids) > 0 and team.id != 0 do
          ids = Enum.map(ids, fn id -> String.to_integer(id) end)
          ids = ids ++ Mentors.list_mentee_ids(ids)
          receivers = User
            |> where([u], u.id in ^ids)
            |> preload([:devices])
            |> Repo.all()
          Notifications.process_team_passed_leaderboard(team, receivers)
        end

        # For universities
        before_change = university.semester_points - abs(audit.points) + 1
        after_change = university.semester_points - 1
        {:ok, ids} = service(BillBored.Redix).command(["ZRANGEBYSCORE", university_semester_key(), "#{before_change}", "#{after_change}"])
        if length(ids) > 0 and university.id != 0 do
          ids = Enum.map(ids, fn id -> String.to_integer(id) end)
          receivers = User
            |> where([u], u.university_id in ^ids)
            |> preload([:devices])
            |> Repo.all()
          Notifications.process_university_passed_leaderboard(university, receivers)
        end
      end)
    end
  end

  defp other_uni_user_queryable(nil, university_id) do
    User |> where([u], u.university_id != ^university_id)
  end

  defp other_uni_user_queryable(user_id, _university_id) do
    User |> where([u], u.id == ^user_id)
  end

  def user_points_cache(user_id, university_id \\ nil) do
    user = other_uni_user_queryable(user_id, university_id)
      |> preload([:university, :mentor, :mentee, :points])
      |> limit(1)
      |> Repo.one()

    if is_nil(user) do
      nil
    else
      commands = [
        ["ZSCORE", user_semester_key(), to_string(user.id)],
        ["ZSCORE", user_monthly_key(), to_string(user.id)],
        ["ZSCORE", user_weekly_key(), to_string(user.id)],
        ["ZSCORE", user_daily_key(), to_string(user.id)]
      ]

      {:ok, [semester_points, monthly_points, weekly_points, daily_points]} = service(BillBored.Redix).pipeline(commands)

      %{user |
        semester_points: String.to_integer(semester_points || "0"),
        monthly_points: String.to_integer(monthly_points || "0"),
        weekly_points: String.to_integer(weekly_points || "0"),
        daily_points: String.to_integer(daily_points || "0"),
        total_points: (user.points || %{general_points: 0}).general_points || 0
      }
    end
  end

  def ahead_user_points_cache(points, university_id) do
    {micro_secs, _} = :timer.tc(service(BillBored.Redix), :command, [["ZDIFFSTORE", "#{user_semester_key()}:#{university_id}", "2", user_semester_key(), "university:#{university_id}:members"]])
    IO.inspect("Load Other Uni User Data: Time-Consuming #{micro_secs / 1000000} seconds")
    {:ok, ids} = service(BillBored.Redix).command(["ZRANGEBYSCORE", "#{user_semester_key()}:#{university_id}", "#{points + 1}", "+inf", "LIMIT", "0", "1"])
    if length(ids) > 0 do
      user_points_cache(String.to_integer(Enum.at(ids, 0)))
    else
      nil
    end
  end

  def behind_user_points_cache(points, university_id) do
    {micro_secs, _} = :timer.tc(service(BillBored.Redix), :command, [["ZDIFFSTORE", "#{user_semester_key()}:#{university_id}", "2", user_semester_key(), "university:#{university_id}:members"]])
    IO.inspect("Load Other Uni User Data: Time-Consuming #{micro_secs / 1000000} seconds")
    {:ok, ids} = service(BillBored.Redix).command(["ZREVRANGEBYSCORE", "#{user_semester_key()}:#{university_id}", "#{points - 1}", "-inf", "LIMIT", "0", "1"])
    if length(ids) > 0 do
      user_points_cache(String.to_integer(Enum.at(ids, 0)))
    else
      user_points_cache(nil, university_id)
    end
  end

  def team_points_cache(mentor_id, university_id \\ nil) do
    total_query = Mentors.query_general_points_between

    user = other_uni_user_queryable(mentor_id, university_id)
      |> join(:inner, [u], upa in subquery(total_query), on: upa.user_id == u.id, as: :total)
      |> select_merge([
        total: total
      ], %{
        total_points: fragment("COALESCE(?, 0)", total.points)
      })
      |> preload([:mentees])
      |> limit(1)
      |> Repo.one()

    if is_nil(user) do
      nil
    else
      commands = [
        ["ZSCORE", team_semester_key(), to_string(user.id)],
        ["ZSCORE", team_monthly_key(), to_string(user.id)],
        ["ZSCORE", team_weekly_key(), to_string(user.id)],
        ["ZSCORE", team_daily_key(), to_string(user.id)]
      ]

      {:ok, [semester_points, monthly_points, weekly_points, daily_points]} = service(BillBored.Redix).pipeline(commands)

      %{user |
        semester_points: String.to_integer(semester_points || "0"),
        monthly_points: String.to_integer(monthly_points || "0"),
        weekly_points: String.to_integer(weekly_points || "0"),
        daily_points: String.to_integer(daily_points || "0")
      }
    end
  end

  def ahead_team_points_cache(points, university_id) do
    {micro_secs, _} = :timer.tc(service(BillBored.Redix), :command, [["ZDIFFSTORE", "#{team_semester_key()}:#{university_id}", "2", team_semester_key(), "university:#{university_id}:members"]])
    IO.inspect("Load Other Uni Team Data: Time-Consuming #{micro_secs / 1000000} seconds")
    {:ok, ids} = service(BillBored.Redix).command(["ZRANGEBYSCORE", "#{team_semester_key()}:#{university_id}", "#{points + 1}", "+inf", "LIMIT", "0", "1"])
    if length(ids) > 0 do
      team_points_cache(String.to_integer(Enum.at(ids, 0)))
    else
      nil
    end
  end

  def behind_team_points_cache(points, university_id) do
    {micro_secs, _} = :timer.tc(service(BillBored.Redix), :command, [["ZDIFFSTORE", "#{team_semester_key()}:#{university_id}", "2", team_semester_key(), "university:#{university_id}:members"]])
    IO.inspect("Load Other Uni User Data: Time-Consuming #{micro_secs / 1000000} seconds")
    {:ok, ids} = service(BillBored.Redix).command(["ZREVRANGEBYSCORE", "#{team_semester_key()}:#{university_id}", "#{points - 1}", "-inf", "LIMIT", "0", "1"])
    if length(ids) > 0 do
      team_points_cache(String.to_integer(Enum.at(ids, 0)))
    else
      team_points_cache(nil, university_id)
    end
  end

  defp university_other_queryable(nil, university_id) do
    University |> where([u], u.id != ^university_id)
  end

  defp university_other_queryable(self_id, _university_id) do
    University |> where([u], u.id == ^self_id)
  end

  def university_points_cache(university_id, other_university_id \\ nil) do
    total_query = Universities.query_general_points_between

    university = university_other_queryable(university_id, other_university_id)
      |> join(:inner, [u], upa in subquery(total_query), on: upa.university_id == u.id, as: :total)
      |> select_merge([
        total: total
      ], %{
        total_points: fragment("COALESCE(?, 0)", total.points)
      })
      |> limit(1)
      |> Repo.one()

    if is_nil(university) do
      nil
    else
      commands = [
        ["ZSCORE", university_semester_key(), to_string(university.id)],
        ["ZSCORE", university_monthly_key(), to_string(university.id)],
        ["ZSCORE", university_weekly_key(), to_string(university.id)],
        ["ZSCORE", university_daily_key(), to_string(university.id)]
      ]

      {:ok, [semester_points, monthly_points, weekly_points, daily_points]} = service(BillBored.Redix).pipeline(commands)

      %{university |
        semester_points: String.to_integer(semester_points || "0"),
        monthly_points: String.to_integer(monthly_points || "0"),
        weekly_points: String.to_integer(weekly_points || "0"),
        daily_points: String.to_integer(daily_points || "0")
      }
    end
  end

  def ahead_university_points_cache(points, _university_id) do
    {:ok, ids} = service(BillBored.Redix).command(["ZRANGEBYSCORE", university_semester_key(), "#{points + 1}", "+inf", "LIMIT", "0", "1"])
    if length(ids) > 0 do
      university_points_cache(String.to_integer(Enum.at(ids, 0)))
    else
      nil
    end
  end

  def behind_university_points_cache(points, university_id) do
    {:ok, ids} = service(BillBored.Redix).command(["ZREVRANGEBYSCORE", university_semester_key(), "#{points - 1}", "-inf", "LIMIT", "0", "1"])
    if length(ids) > 0 do
      university_points_cache(String.to_integer(Enum.at(ids, 0)))
    else
      university_points_cache(nil, university_id)
    end
  end

  def team_daily_notification() do
    if Mix.env() != :test do
      # top team
      {:ok, ids} = service(BillBored.Redix).command(["ZREVRANGEBYSCORE", team_daily_key(), "+inf", "-inf", "WITHSCORES", "LIMIT", "0", "1"])
      if length(ids) > 0 do
        mentor_id = String.to_integer(Enum.at(ids, 0))
        daily_points = String.to_integer(Enum.at(ids, 1))
        team = User
          |> where([u], u.id == ^mentor_id)
          |> preload([:university, :devices])
          |> Repo.one()

        if not is_nil(team) and not is_nil(team.university_id) do
          team = %{
            team |
            daily_points: daily_points
          }
          {micro_secs, _} = :timer.tc(service(BillBored.Redix), :command, [["ZDIFFSTORE", "#{team_daily_key()}:#{team.university_id}", "2", team_daily_key(), "university:#{team.university_id}:members"]])
          IO.inspect("Load Other Uni Team Data: Time-Consuming #{micro_secs / 1000000} seconds")
          {:ok, ids} = service(BillBored.Redix).command(["ZREVRANGEBYSCORE", "#{team_daily_key()}:#{team.university_id}", "#{daily_points}", "-inf", "WITHSCORES"])
          if length(ids) > 0 do
            1..floor(length(ids) / 2)
              |> Enum.map(fn index ->
                mentor_id = String.to_integer(Enum.at(ids, (index - 1) * 2))
                points = String.to_integer(Enum.at(ids, (index - 1) * 2 + 1))
                if index == 1 do
                  opposite_team = User
                    |> where([u], u.id == ^mentor_id)
                    |> preload([:university])
                    |> Repo.one()
                  opposite_team = %{
                    opposite_team |
                    daily_points: points
                  }
                  receivers = User
                    |> where([u], u.university_id == ^team.university_id)
                    |> preload([:devices])
                    |> Repo.all()
                  Notifications.encourage_winning_team(receivers, team, opposite_team)
                end
                ids = [mentor_id | Mentors.list_mentee_ids(mentor_id)]
                receivers = User
                  |> where([u], u.id in ^ids)
                  |> preload([:devices])
                  |> Repo.all()
                Notifications.encourage_opposite_team(receivers, team, %{id: mentor_id, daily_points: points})
              end)
          end
        end
      end
    end
  end

  # def get_number_of_activites_in_conversations(user_id) do
  #   after_date = DateTime.add(DateTime.utc_now(), 7 * 24 * 3600)
  #   from(u in User,
  #     left_join: cm in ChatMessage,
  #     on: u.id == cm.user_id and cm.user_id == ^user_id and cm.created > ^after_date,
  #     left_join: s in DropchatStream,
  #     on: u.id == s.admin_id and s.admin_id == ^user_id and s.inserted_at > ^after_date,
  #     left_join: sr in DropchatStreamReaction,
  #     on: u.id == sr.user_id and sr.user_id == ^user_id and sr.inserted_at > ^after_date,
  #     left_join: ss in DropchatStreamSpeaker,
  #     on: u.id == ss.user_id and ss.user_id == ^user_id and ss.inserted_at > ^after_date,
  #     left_join: l in Livestream,
  #     on: u.id == l.owner_id and l.owner_id == ^user_id and l.created > ^after_date,
  #     left_join: lc in LivestreamComment,
  #     on: u.id == lc.author_id and lc.author_id == ^user_id and lc.created > ^after_date,
  #     left_join: lcv in LivestreamCommentVote,
  #     on: u.id == lcv.user_id and lcv.user_id == ^user_id and lcv.created > ^after_date,
  #     left_join: lv in LivestreamView,
  #     on: u.id == lv.user_id and lv.user_id == ^user_id and lv.created > ^after_date,
  #     left_join: lvt in LivestreamVote,
  #     on: u.id == lvt.user_id and lvt.user_id == ^user_id and lvt.created > ^after_date,
  #     where: u.id == ^user_id,
  #     select: %{
  #       count: count(fragment("DISTINCT ?", cm.id)) +
  #         count(fragment("DISTINCT ?", s.id)) +
  #         count(fragment("DISTINCT ?", ss.id)) +
  #         count(fragment("DISTINCT ?", sr.id)) +
  #         count(fragment("DISTINCT ?", l.id)) +
  #         count(fragment("DISTINCT ?", lc.id)) +
  #         count(fragment("DISTINCT ?", lcv.created)) +
  #         count(fragment("DISTINCT ?", lv.created)) +
  #         count(fragment("DISTINCT ?", lvt.created))
  #     },
  #     group_by: u.id
  #   )
  #   |> Repo.one()
  #   |> Map.get(:count, 0)
  # end
end
