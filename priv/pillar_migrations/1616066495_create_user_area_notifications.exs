defmodule Pillar.Migrations.Create_user_area_notifications do
  def up do
    """
    CREATE TABLE IF NOT EXISTS user_area_notifications (
      user_id UInt64,
      timestamp UInt32,
      sent_at DateTime
    ) ENGINE = MergeTree()
    ORDER BY (user_id, timestamp)
    TTL sent_at + INTERVAL 30 DAY
    """
  end

  def down do
    "DROP TABLE user_area_notifications"
  end
end
