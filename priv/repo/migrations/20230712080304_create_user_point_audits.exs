defmodule Repo.Migrations.CreateUserPointAudits do
  require Logger
  use Ecto.Migration

  def change do
    execute("""
      CREATE TABLE IF NOT EXISTS user_point_audits (
        id SERIAL,
        user_id int,
        points int,
        p_type varchar(50) NOT NULL,
        reason varchar(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) PARTITION BY LIST (MOD(CAST(EXTRACT(year from created_at) AS INTEGER), 10));
    """)
    execute("CREATE TABLE user_point_audits_0 PARTITION OF user_point_audits FOR VALUES IN (0);")
    execute("CREATE TABLE user_point_audits_1 PARTITION OF user_point_audits FOR VALUES IN (1);")
    execute("CREATE TABLE user_point_audits_2 PARTITION OF user_point_audits FOR VALUES IN (2);")
    execute("CREATE TABLE user_point_audits_3 PARTITION OF user_point_audits FOR VALUES IN (3);")
    execute("CREATE TABLE user_point_audits_4 PARTITION OF user_point_audits FOR VALUES IN (4);")
    execute("CREATE TABLE user_point_audits_5 PARTITION OF user_point_audits FOR VALUES IN (5);")
    execute("CREATE TABLE user_point_audits_6 PARTITION OF user_point_audits FOR VALUES IN (6);")
    execute("CREATE TABLE user_point_audits_7 PARTITION OF user_point_audits FOR VALUES IN (7);")
    execute("CREATE TABLE user_point_audits_8 PARTITION OF user_point_audits FOR VALUES IN (8);")
    execute("CREATE TABLE user_point_audits_9 PARTITION OF user_point_audits FOR VALUES IN (9);")
    execute("CREATE INDEX user_point_audits_0_user_id_idx ON user_point_audits_0 (user_id);")
    execute("CREATE INDEX user_point_audits_1_user_id_idx ON user_point_audits_1 (user_id);")
    execute("CREATE INDEX user_point_audits_2_user_id_idx ON user_point_audits_2 (user_id);")
    execute("CREATE INDEX user_point_audits_3_user_id_idx ON user_point_audits_3 (user_id);")
    execute("CREATE INDEX user_point_audits_4_user_id_idx ON user_point_audits_4 (user_id);")
    execute("CREATE INDEX user_point_audits_5_user_id_idx ON user_point_audits_5 (user_id);")
    execute("CREATE INDEX user_point_audits_6_user_id_idx ON user_point_audits_6 (user_id);")
    execute("CREATE INDEX user_point_audits_7_user_id_idx ON user_point_audits_7 (user_id);")
    execute("CREATE INDEX user_point_audits_8_user_id_idx ON user_point_audits_8 (user_id);")
    execute("CREATE INDEX user_point_audits_9_user_id_idx ON user_point_audits_9 (user_id);")
    execute("""
      CREATE OR REPLACE FUNCTION truncate_old_user_point_audits()
      RETURNS VOID AS $$
      DECLARE
        table_name text;
        query	text;
      BEGIN
        table_name := CONCAT('user_point_audits_', MOD((CAST(EXTRACT(YEAR FROM CURRENT_TIMESTAMP) AS INTEGER) - 3), 10));
        query := 'TRUNCATE TABLE ' || table_name;
        EXECUTE query;
      END;
      $$ LANGUAGE plpgsql;
    """)
    # execute("SELECT cron.schedule_in_database('truncate-old-point-audits', '0 0 1 1 *', 'SELECT truncate_old_user_point_audits();', '#{Application.get_env(:billbored, Repo)[:database]}');")
  end
end
