defmodule Pillar.Migrations.Create_post_views do
  def up do
    """
    CREATE TABLE IF NOT EXISTS post_views (
      post_id UInt64,
      business_id Nullable(UInt64),
      geohash String,
      lon Float32,
      lat Float32,
      user_id UInt64,
      age Nullable(UInt8),
      sex LowCardinality(String),
      country LowCardinality(Nullable(String)),
      city Nullable(String),
      viewed_at DateTime
    ) ENGINE = MergeTree()
    ORDER BY (post_id, viewed_at)
    PARTITION BY toYYYYMM(toDate(viewed_at))
    """
  end

  def down do
    "DROP TABLE post_views"
  end
end
