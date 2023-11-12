defmodule Pillar.Migrations.Create_business_posts do
  def up do
    """
    CREATE MATERIALIZED VIEW business_posts (
      business_id UInt64,
      post_id UInt64
    ) ENGINE = ReplacingMergeTree()
    ORDER BY (business_id, post_id)
    POPULATE AS SELECT business_id, post_id FROM post_views WHERE business_id IS NOT NULL
    """
  end

  def down do
    "DROP TABLE business_posts"
  end
end
