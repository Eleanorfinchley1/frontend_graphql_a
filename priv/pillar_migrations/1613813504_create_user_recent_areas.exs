defmodule Pillar.Migrations.Create_user_recent_areas do
  def up do
    """
    CREATE MATERIALIZED VIEW user_recent_areas
    ENGINE = AggregatingMergeTree()
    PARTITION BY toYYYYMM(visited_at)
    ORDER BY (user_id, visited_at)
    TTL visited_at + INTERVAL 180 DAY
    AS
      SELECT
        user_id,
        date_trunc('week', visited_at) AS visited_at,
        substring(geohash, 1, 6) AS geohash,
        countState() AS visitsCount
      FROM user_locations
      GROUP BY user_id, visited_at, geohash
    """
  end

  def down do
    "DROP TABLE user_recent_areas"
  end
end
