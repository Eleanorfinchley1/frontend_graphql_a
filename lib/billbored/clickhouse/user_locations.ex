defmodule BillBored.Clickhouse.UserLocations do
  alias BillBored.Clickhouse.UserLocation
  alias BillBored.Geo
  alias BillBored.Notifications.AreaNotification

  def create(%UserLocation{} = user_location) do
    Pillar.insert(
      BillBored.Clickhouse.conn(),
      """
        INSERT INTO user_locations (
          user_id, geohash, visited_at
        ) VALUES (
          {user_id}, {geohash}, {visited_at}
        )
      """,
      Map.from_struct(user_location)
    )
  end

  @area_precision 6

  def get_recently_visited_areas(user_id, %Geo.Point{} = point, radius, period_days \\ 14) do
    with {:ok, geohashes} <- Geo.Hash.all_within_safe(point, radius, @area_precision),
         now <- Timex.today(),
         datetime_from <- Timex.beginning_of_week(Timex.shift(now, days: -period_days)) do
      Pillar.select(
        BillBored.Clickhouse.conn(),
        """
          SELECT DISTINCT geohash
          FROM user_recent_areas
          WHERE
            user_id = {user_id} AND
            visited_at >= {datetime_from} AND
            visited_at <= {datetime_to} AND
            geohash IN ({geohashes})
        """,
        %{user_id: user_id, datetime_from: datetime_from, datetime_to: now, geohashes: geohashes}
      )
    end
  end

  def get_users_for_area_notification(%AreaNotification{location: location, radius: radius}, max_daily_notifications, period_days \\ 14, now \\ DateTime.utc_now()) do
    with {:ok, geohashes} <- Geo.Hash.all_within_safe(location, radius, @area_precision),
         today <- DateTime.to_date(now),
         datetime_from <- Timex.beginning_of_week(Timex.shift(today, days: -period_days)),
         timestamp <- Timex.beginning_of_day(now) |> DateTime.to_unix() do
      Pillar.select(
        BillBored.Clickhouse.conn(),
        """
          SELECT groupArray(user_id) AS user_ids
          FROM (
            SELECT ura.user_id AS user_id, countIf(uan.timestamp = {timestamp}) AS count
            FROM user_recent_areas ura
            LEFT JOIN user_area_notifications uan
            ON ura.user_id = uan.user_id
            WHERE
              ura.visited_at >= {datetime_from} AND
              ura.visited_at <= {datetime_to} AND
              ura.geohash IN ({geohashes})
            GROUP BY ura.user_id
            LIMIT 10000
          )
          WHERE count < {max_daily_notifications}
        """,
        %{
          datetime_from: datetime_from,
          datetime_to: today,
          timestamp: timestamp,
          max_daily_notifications: max_daily_notifications,
          geohashes: geohashes
        }
      )
    end
  end
end
