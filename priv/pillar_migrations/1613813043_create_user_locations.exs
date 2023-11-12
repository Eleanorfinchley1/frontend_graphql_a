defmodule Pillar.Migrations.Create_user_locations do
  def up do
    """
    CREATE TABLE IF NOT EXISTS user_locations (
      user_id UInt64,
      geohash String,
      visited_at DateTime
    ) ENGINE = MergeTree()
    ORDER BY (user_id, visited_at)
    TTL visited_at + INTERVAL 1 DAY
    """
  end

  def down do
    "DROP TABLE user_locations"
  end
end
