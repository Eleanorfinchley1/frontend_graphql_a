defmodule BillBored.Notifications.AreaNotifications.TimetableEntries do
  import Ecto.Query

  alias BillBored.User
  alias BillBored.Notifications.AreaNotification
  alias BillBored.Notifications.AreaNotifications.TimetableEntry
  alias BillBored.Notifications.AreaNotifications.TimetableRun

  require Logger

  def start_pending_runs(now \\ DateTime.utc_now()) do
    timestamp = Timex.beginning_of_day(now) |> DateTime.to_unix()

    result =
      Ecto.Multi.new()
      |> select_pending_area_notifications(now, timestamp)
      |> insert_timetable_runs(timestamp)
      |> Repo.transaction()

    with {:ok, %{insert_timetable_runs: timetable_runs}} <- result do
      {:ok, timetable_runs}
    end
  end

  defmacrop timezoned_time_lt_now(timezone, time, now) do
    quote do
      fragment(
        "(date(timezone(COALESCE(?, 'UTC'), ?)) + ? < timezone(COALESCE(?, 'UTC'), ?))",
        unquote(timezone),
        ^unquote(now),
        unquote(time),
        unquote(timezone),
        ^unquote(now)
      )
    end
  end

  defp select_pending_area_notifications(multi, now, timestamp) do
    Ecto.Multi.run(multi, :select_area_notifications, fn _, _ ->
      area_notifications =
        from(an in AreaNotification,
          join: te in TimetableEntry,
          left_join: tr in TimetableRun,
          on:
            tr.timetable_entry_id == te.id and
              tr.area_notification_id == an.id and
              tr.timestamp == ^timestamp,
          where:
            timezoned_time_lt_now(an.timezone, te.time, now) and
              is_nil(tr.id) and
              (is_nil(an.expires_at) or an.expires_at > ^now) and
              (te.any_category or fragment("(? && ?)", an.categories, te.categories)),
          preload: [timetable_entries: te]
        )
        |> Repo.all()

      {:ok, area_notifications}
    end)
  end

  defp insert_timetable_runs(multi, timestamp) do
    Ecto.Multi.run(multi, :insert_timetable_runs, fn _,
                                                     %{
                                                       select_area_notifications:
                                                         area_notifications
                                                     } ->
      now = DateTime.utc_now()

      runs_attrs =
        Enum.flat_map(area_notifications, fn %{
                                          id: area_notification_id,
                                          timetable_entries: timetable_entries
                                        } ->
          Enum.map(timetable_entries, fn %{id: timetable_entry_id} ->
            %{
              area_notification_id: area_notification_id,
              timetable_entry_id: timetable_entry_id,
              timestamp: timestamp,
              inserted_at: now,
              updated_at: now
            }
          end)
        end)
        |> Enum.uniq_by(fn %{area_notification_id: an_id, timetable_entry_id: tte_id} -> {an_id, tte_id} end)

      {_, inserted} = Repo.insert_all(TimetableRun, runs_attrs, returning: true)
      {:ok, Repo.preload(inserted, [:area_notification, :timetable_entry])}
    end)
  end

  def group_user_runs(runs_user_sets) do
    {user_set_runs, _} =
      Enum.reduce(runs_user_sets, {[], nil}, fn
        {new_timetable_run, new_user_set}, {[], nil} ->
          {[{new_user_set, [new_timetable_run]}], new_user_set}

        {new_timetable_run, new_user_set}, {acc, all_user_set} ->
          new_acc =
            Enum.flat_map(acc, fn {user_set, timetable_runs} ->
              inter_set = MapSet.intersection(user_set, new_user_set)
              diff_set = MapSet.difference(user_set, new_user_set)
              new_set = MapSet.difference(new_user_set, all_user_set)

              [
                {inter_set, [new_timetable_run | timetable_runs]},
                {diff_set, timetable_runs},
                {new_set, [new_timetable_run]}
              ]
              |> Enum.reject(fn {set, _} -> MapSet.size(set) == 0 end)
            end)

          {new_acc, MapSet.union(all_user_set, new_user_set)}
      end)

    user_set_runs
  end

  @max_daily_notifications 4

  def send_pending_notifications() do
    Logger.info("Begin send pending notifications")

    with {:ok, runs} <- start_pending_runs(),
         grouped_runs <- Enum.group_by(runs, fn %{timestamp: timestamp, timetable_entry: timetable_entry} -> {timestamp, timetable_entry} end) do
      Enum.each(grouped_runs, fn {{timestamp, %{template: template}}, runs} ->
        {runs_user_sets, receivers} =
          Enum.reduce(runs, {[], %{}}, fn %{area_notification: area_notification} = timetable_run, {acc, receivers} ->
            with {:ok, [%{"user_ids" => user_ids}]} <- BillBored.Clickhouse.UserLocations.get_users_for_area_notification(area_notification, @max_daily_notifications) do
              receivers_by_id =
                user_ids
                |> Stream.chunk_every(1000)
                |> Stream.flat_map(fn user_ids ->
                  from(u in User,
                    join: d in assoc(u, :devices),
                    where: u.id in ^user_ids,
                    preload: [devices: d]
                  )
                  |> Repo.all()
                end)
                |> Stream.map(fn %{id: id} = receiver -> {id, receiver} end)
                |> Enum.into(%{})

              {[{timetable_run, MapSet.new(user_ids)} | acc], Map.merge(receivers, receivers_by_id)}
            else
              _ ->
                {acc, receivers}
            end
          end)

        user_set_runs = group_user_runs(runs_user_sets)

        user_set_runs
        |> Enum.each(fn {user_set, runs} ->
          Logger.info("Queueing push for #{length(runs)} area notifications to #{MapSet.size(user_set)} users")
          Logger.debug(inspect(runs, pretty: true))

          receivers = Enum.map(user_set, fn user_id -> receivers[user_id] end) |> Enum.reject(&(is_nil(&1)))

          Enum.chunk_every(receivers, 1000)
          |> Enum.each(fn receivers ->
            Notifications.scheduled_area_notification(%{
              timestamp: timestamp,
              template: template,
              timetable_runs: runs,
              receivers: receivers
            })
          end)
        end)
      end)
    end

    Logger.info("End send pending notifications")
  end
end
