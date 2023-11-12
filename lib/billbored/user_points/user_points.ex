defmodule BillBored.UserPoints do
  @moduledoc ""
  import Ecto.Query

  alias BillBored.User
  alias BillBored.UserPoint
  alias BillBored.UserPoint.Audit, as: UserPointAudit
  alias BillBored.Chat.Message, as: ChatMessage
  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStream.Reaction, as: DropchatStreamReaction
  alias BillBored.Chat.Room.DropchatStream.Speaker, as: DropchatStreamSpeaker
  alias BillBored.Livestream
  alias BillBored.Livestream.Comment, as: LivestreamComment
  alias BillBored.Livestream.Comment.Vote, as: LivestreamCommentVote
  alias BillBored.Livestream.View, as: LivestreamView
  alias BillBored.Livestream.Vote, as: LivestreamVote

  @default_reactions_count %{"like" => 0, "dislike" => 0, "clapping" => 0}

  def query_general_points_between(period \\ nil)

  def query_general_points_between(period) when is_nil(period) do
    UserPoint
    |> select([upa], %{
      user_id: upa.user_id,
      points: upa.general_points,
      p_type: "general"
    })
  end

  def query_general_points_between({start_dt, end_dt}) do
    UserPointAudit
    |> where(
        [upa],
        upa.created_at >= ^start_dt and
        upa.created_at < ^end_dt and
        (upa.reason == "streaming" or upa.p_type == "general")
    )
    |> group_by([upa], upa.user_id)
    |> select([upa], %{
      user_id: upa.user_id,
      points: fragment("COALESCE(SUM(ABS(?))::integer, 0)", upa.points),
      p_type: "general"
    })
  end

  def get(user_id) do
    UserPoint
    |> where(user_id: ^user_id)
    |> Repo.one()
  end

  def give_signup_points(user_id, joined \\ nil) do
    create_audit(%{
      "user_id" => user_id,
      "points" => signup_points(),
      "p_type" => "stream",
      "reason" => "signup",
      "created_at" => joined
    })
  end

  def give_referral_points(user_id) do
    create_audit(%{
      "user_id" => user_id,
      "points" => referral_points(),
      "p_type" => "stream",
      "reason" => "referral"
    })
  end

  def give_anticipation_points(user_id) do
    create_audit(%{
      "user_id" => user_id,
      "points" => anticipation_points(),
      "p_type" => "stream",
      "reason" => "anticipation"
    })
  end

  def double_points_by_anticipation(user_id) do
    user_points = get(user_id)
    if not is_nil(user_points) do
      create_audit(%{
        "user_id" => user_id,
        "points" => max(user_points.stream_points, 100),
        "p_type" => "stream",
        "reason" => "anticipation_double"
      })
    end
  end

  def give_peak_points(%DropchatStream{} = dropchat_stream) do
    reactions_count = if dropchat_stream.reactions_count do
      Map.merge(@default_reactions_count, dropchat_stream.reactions_count)
    else
      @default_reactions_count
    end

    percentage = peak_points_percentages()
    points = round((dropchat_stream.peak_audience_count * percentage[:listeners] + reactions_count["like"] * percentage[:likes] + reactions_count["clapping"] * percentage[:claps]) / 100)
    if points > 0 do
      create_audit(%{
        "user_id" => dropchat_stream.admin_id,
        "points" => points * 10,
        "p_type" => "stream",
        "reason" => "peak"
      })
    end
  end

  def give_location_points(user_id, location_rewards) do
    points = Enum.reduce(location_rewards, 0, fn reward, total -> total + reward.stream_points end)
    create_audit(%{
      "user_id" => user_id,
      "points" => points,
      "p_type" => "stream",
      "reason" => "location"
    })
  end

  def give_daily_points() do
    current_time = DateTime.utc_now()
    query =
      from(u in User,
      left_join: last_daily in subquery(
        from(upa in UserPointAudit,
          where: upa.reason == "daily",
          group_by:  upa.user_id,
          select: %{
            user_id: upa.user_id,
            created_at: fragment("max(?)", upa.created_at),
            points: 0
          }
        )
      ),
      on: last_daily.user_id == u.id,
      left_join: upa in UserPointAudit,
      on: u.id == upa.user_id and upa.reason == "streaming" and upa.created_at >= fragment("COALESCE(?, ?)", last_daily.created_at, ^current_time),
      where: is_nil(u.event_provider) and u.banned? == false and u.deleted? == false,
      select: %{
        user_id: u.id,
        points: fragment("?-greatest(0, coalesce(? - ?, 0) + coalesce(sum(?)::integer, 0))", ^daily_points(), ^daily_points(), last_daily.points, upa.points),
        p_type: "stream",
        reason: "daily"
      },
      group_by: [u.id, last_daily.points])

    Repo.all(query)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce({0, []}, fn chunk, {num_rows, rows} ->
      {count, items} = Repo.insert_all(UserPointAudit, chunk, returning: [:id, :user_id, :points, :p_type, :reason, :created_at])
      {num_rows + count, rows ++ items}
    end)
  end

  def expire_signup_points() do
    expire_date = DateTime.add(DateTime.utc_now(), trunc(-signup_points_available_hours() * 3600))
    query =
      from(upa in UserPointAudit,
      join: signups in subquery(
        from upa in UserPointAudit,
        where: upa.reason == "signup",
        # where: upa.created_at <= fragment("CURRENT_TIMESTAMP") - fragment("?::interval", ^%Postgrex.Interval{
        #   months: 0, days: 0, secs: signup_points_available_hours() * 3600, microsecs: 0
        # }),
        where: upa.created_at <= ^expire_date,
        select: upa.user_id
      ),
      on: upa.user_id == signups.user_id,
      left_join: upa2 in UserPointAudit,
      on: upa2.user_id == upa.user_id and upa2.reason == "signup_expire",
      where: upa.reason == "signup" or upa.points < 0,
      where: is_nil(upa2.user_id),
      select: %{
        user_id: upa.user_id,
        points: fragment("-greatest(0, ?)", sum(upa.points)),
        p_type: "stream",
        reason: "signup_expire"
      },
      group_by: upa.user_id)

    Repo.all(query)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce({0, []}, fn chunk, {num_rows, rows} ->
      {count, items} = Repo.insert_all(UserPointAudit, chunk, returning: [:id, :user_id, :points, :p_type, :reason, :created_at])
      {num_rows + count, rows ++ items}
    end)
  end

  def expire_signup_points(user_id) do
    expire_date = DateTime.add(DateTime.utc_now(), -signup_points_available_hours() * 3600)
    query =
      from(upa in UserPointAudit,
      join: signups in subquery(
        from upa in UserPointAudit,
        where: upa.reason == "signup",
        # where: upa.created_at <= fragment("CURRENT_TIMESTAMP") - fragment("?::interval", ^%Postgrex.Interval{
        #   months: 0, days: 0, secs: signup_points_available_hours() * 3600, microsecs: 0
        # }),
        where: upa.created_at <= ^expire_date,
        where: upa.user_id == ^user_id,
        select: upa.user_id
      ),
      on: upa.user_id == signups.user_id,
      left_join: upa2 in UserPointAudit,
      on: upa2.user_id == upa.user_id and upa2.reason == "signup_expire",
      where: upa.reason == "signup" or upa.points < 0,
      where: is_nil(upa2.user_id),
      select: %{
        user_id: upa.user_id,
        points: fragment("-greatest(0, ?::integer)", sum(upa.points)),
        p_type: "stream",
        reason: "signup_expire"
      },
      group_by: upa.user_id)

    Repo.all(query)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce({0, []}, fn chunk, {num_rows, rows} ->
      {count, items} = Repo.insert_all(UserPointAudit, chunk, returning: [:id, :user_id, :points, :p_type, :reason, :created_at])
      {num_rows + count, rows ++ items}
    end)
  end

  def stream_available_minutes_with_points(user_id) do
    user_points = get(user_id)
    trunc((if is_nil(user_points), do: 0, else: user_points.stream_points) / points_per_minute())
  end

  def reduce_during_streaming(user_id, minutes \\ 1, _stream_id \\ -1) do
    user_points = get(user_id)
    if not is_nil(user_points) do
      create_audit(%{
        "user_id" => user_id,
        "points" => -min(minutes * points_per_minute(), user_points.stream_points),
        "p_type" => "stream",
        "reason" => "streaming"
      })
    end
  end

  def reduce_during_absent() do
    from_date = DateTime.add(DateTime.utc_now(), -absent_days() * 2 * 24 * 3600)
    to_date = DateTime.add(DateTime.utc_now(), -absent_days() * 24 * 3600)
    query = from(up in UserPoint,
      join: upa in UserPointAudit,
      on: up.user_id == upa.user_id and upa.p_type == "stream" and upa.reason != "daily" and upa.created_at <= ^to_date and upa.created_at >= ^from_date,
      left_join: ap in subquery(
        from u in User,
        left_join: cm in ChatMessage,
        on: u.id == cm.user_id and cm.created > ^to_date,
        left_join: s in DropchatStream,
        on: u.id == s.admin_id and s.inserted_at > ^to_date,
        left_join: sr in DropchatStreamReaction,
        on: u.id == sr.user_id and sr.inserted_at > ^to_date,
        left_join: ss in DropchatStreamSpeaker,
        on: u.id == ss.user_id and ss.inserted_at > ^to_date,
        left_join: l in Livestream,
        on: u.id == l.owner_id and l.created > ^to_date,
        left_join: lc in LivestreamComment,
        on: u.id == lc.author_id and lc.created > ^to_date,
        left_join: lcv in LivestreamCommentVote,
        on: u.id == lcv.user_id and lcv.created > ^to_date,
        left_join: lv in LivestreamView,
        on: u.id == lv.user_id and lv.created > ^to_date,
        left_join: lvt in LivestreamVote,
        on: u.id == lvt.user_id and lvt.created > ^to_date,
        where: u.date_joined < ^to_date,
        where: is_nil(u.event_provider) and u.banned? == false and u.deleted? == false,
        select: %{
          user_id: u.id
        },
        group_by: u.id,
        having: count(fragment("DISTINCT ?", cm.id)) +
          count(fragment("DISTINCT ?", s.id)) +
          count(fragment("DISTINCT ?", ss.id)) +
          count(fragment("DISTINCT ?", sr.id)) +
          count(fragment("DISTINCT ?", l.id)) +
          count(fragment("DISTINCT ?", lc.id)) +
          count(fragment("DISTINCT ?", lcv.created)) +
          count(fragment("DISTINCT ?", lv.created)) +
          count(fragment("DISTINCT ?", lvt.created)) > 0
      ),
      on: up.user_id == ap.user_id,
      where: is_nil(ap.user_id),
      where: up.stream_points > 0,
      group_by: up.user_id,
      select: %{
        user_id: up.user_id,
        points: fragment("-?::integer * FLOOR(LEAST(round(abs(SUM(?)) * ? / 100)::integer, SUM(?)::integer)::integer / ?::integer)::integer", ^points_per_minute(), upa.points, ^absent_percentage(), up.stream_points, ^points_per_minute()),
        p_type: "stream",
        reason: "absent"
      })

    Repo.all(query)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce({0, []}, fn chunk, {num_rows, rows} ->
      {count, items} = Repo.insert_all(UserPointAudit, chunk, returning: [:id, :user_id, :points, :p_type, :reason, :created_at])
      {num_rows + count, rows ++ items}
    end)
  end

  def reduce_during_absent(user_id) do
    from_date = DateTime.add(DateTime.utc_now(), -absent_days() * 2 * 24 * 3600)
    to_date = DateTime.add(DateTime.utc_now(), -absent_days() * 24 * 3600)
    query = from(up in UserPoint,
      join: upa in UserPointAudit,
      on: up.user_id == upa.user_id and upa.p_type == "stream" and upa.reason != "daily" and upa.created_at <= ^to_date and upa.created_at >= ^from_date,
      left_join: ap in subquery(
        from u in User,
        left_join: cm in ChatMessage,
        on: u.id == cm.user_id and cm.created > ^to_date,
        left_join: s in DropchatStream,
        on: u.id == s.admin_id and s.inserted_at > ^to_date,
        left_join: sr in DropchatStreamReaction,
        on: u.id == sr.user_id and sr.inserted_at > ^to_date,
        left_join: ss in DropchatStreamSpeaker,
        on: u.id == ss.user_id and ss.inserted_at > ^to_date,
        left_join: l in Livestream,
        on: u.id == l.owner_id and l.created > ^to_date,
        left_join: lc in LivestreamComment,
        on: u.id == lc.author_id and lc.created > ^to_date,
        left_join: lcv in LivestreamCommentVote,
        on: u.id == lcv.user_id and lcv.created > ^to_date,
        left_join: lv in LivestreamView,
        on: u.id == lv.user_id and lv.created > ^to_date,
        left_join: lvt in LivestreamVote,
        on: u.id == lvt.user_id and lvt.created > ^to_date,
        where: u.id == ^user_id,
        where: u.date_joined < ^to_date,
        select: %{
          user_id: u.id
        },
        group_by: u.id,
        having: count(fragment("DISTINCT ?", cm.id)) +
          count(fragment("DISTINCT ?", s.id)) +
          count(fragment("DISTINCT ?", ss.id)) +
          count(fragment("DISTINCT ?", sr.id)) +
          count(fragment("DISTINCT ?", l.id)) +
          count(fragment("DISTINCT ?", lc.id)) +
          count(fragment("DISTINCT ?", lcv.created)) +
          count(fragment("DISTINCT ?", lv.created)) +
          count(fragment("DISTINCT ?", lvt.created)) > 0
      ),
      on: up.user_id == ap.user_id,
      where: up.user_id == ^user_id,
      where: is_nil(ap.user_id),
      where: up.stream_points > 0,
      where: upa.created_at <= ^to_date,
      where: upa.created_at >= ^from_date,
      group_by: up.user_id,
      select: %{
        user_id: up.user_id,
        points: fragment("-?::integer * FLOOR(LEAST(round(abs(SUM(?)) * ? / 100)::integer, SUM(?)::integer)::integer / ?::integer)::integer", ^points_per_minute(), upa.points, ^absent_percentage(), up.stream_points, ^points_per_minute()),
        p_type: "stream",
        reason: "absent"
      })

    Repo.all(query)
    |> Enum.chunk_every(10_000)
    |> Enum.reduce({0, []}, fn chunk, {num_rows, rows} ->
      {count, items} = Repo.insert_all(UserPointAudit, chunk, returning: [:id, :user_id, :points, :p_type, :reason, :created_at])
      {num_rows + count, rows ++ items}
    end)
  end

  def donate_stream_points(sender_id, receiver_id, points) do
    try do
      {2, [sender_audit, receiver_audit]} = Repo.insert_all(UserPointAudit, [
        %{
          user_id: sender_id,
          points: -round(points * 0.75),
          p_type: "stream",
          reason: "donate"
        },
        %{
          user_id: receiver_id,
          points: points,
          p_type: "stream",
          reason: "request"
        }
      ], returning: [:id, :user_id, :points, :p_type, :reason, :created_at])
      {:ok, sender_audit, receiver_audit}
    rescue
      error in Postgrex.Error ->
        {:error, error}
    end
  end

  def create_audit(attr) when is_map(attr) do
    case %UserPointAudit{}
      |> UserPointAudit.changeset(attr)
      |> Repo.insert() do
        {:ok, audit} ->
          Notifications.process_user_point_audit(audit)
          if audit.p_type == "general" or audit.reason == "streaming" do
            spawn(BillBored.Leaderboard, :start_task_to_update_leaderboard, [audit])
          end
          if audit.reason == "streaming" do
            Notifications.process_streaming_audit(audit)
          end
          {:ok, audit}
        others -> others
    end
  end

  def get_audits(user_id, page, count) do
    UserPointAudit
    |> where(user_id: ^user_id)
    |> order_by(desc: :created_at)
    |> limit(^count)
    |> offset(^(page * count))
    |> Repo.all()
  end

  defp signup_points() do
    get_in(Application.get_env(:billbored, __MODULE__), [:signup_points]) ||
      raise("missing #{__MODULE__} signup_points")
  end

  def daily_points() do
    get_in(Application.get_env(:billbored, __MODULE__), [:daily_points]) ||
      raise("missing #{__MODULE__} daily_points")
  end

  defp referral_points() do
    get_in(Application.get_env(:billbored, __MODULE__), [:referral_points]) ||
      raise("missing #{__MODULE__} referral_points")
  end

  defp signup_points_available_hours() do
    get_in(Application.get_env(:billbored, __MODULE__), [:signup_points_available_hours]) ||
      raise("missing #{__MODULE__} signup_points_available_hours")
  end

  defp anticipation_points() do
    get_in(Application.get_env(:billbored, __MODULE__), [:anticipation_points]) ||
      raise("missing #{__MODULE__} anticipation_points")
  end

  defp peak_points_percentages() do
    get_in(Application.get_env(:billbored, __MODULE__), [:peak_percentages]) ||
      raise("missing #{__MODULE__} peak_percentages")
  end

  # defp signin_points() do
  #   get_in(Application.get_env(:billbored, __MODULE__), [:signin_points]) ||
  #     raise("missing #{__MODULE__} signin_points")
  # end

  defp points_per_minute() do
    get_in(Application.get_env(:billbored, __MODULE__), [:points_per_minute]) ||
      raise("missing #{__MODULE__} points_per_minute")
  end

  defp absent_days() do
    get_in(Application.get_env(:billbored, __MODULE__), [:absent_days]) ||
      raise("missing #{__MODULE__} absent_days")
  end

  defp absent_percentage() do
    get_in(Application.get_env(:billbored, __MODULE__), [:absent_percentage]) ||
      raise("missing #{__MODULE__} absent_percentage")
  end
end
