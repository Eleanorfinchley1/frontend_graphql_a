defmodule Repo.Migrations.CreateUserPointsTrigger do
  use Ecto.Migration

  def change do
    execute("""
    CREATE OR REPLACE FUNCTION increase_points_by_audits()
    RETURNS TRIGGER AS $$
    BEGIN
      IF NEW.p_type = 'stream' THEN
        UPDATE user_points SET stream_points = user_points.stream_points + NEW.points WHERE user_id = NEW.user_id;
        IF NOT FOUND THEN
          INSERT INTO user_points (user_id, stream_points, general_points)
          VALUES (NEW.user_id, NEW.points, 0);
        END IF;
      END IF;
      IF NEW.p_type = 'general' THEN
        UPDATE user_points SET general_points = user_points.general_points + NEW.points WHERE user_id = NEW.user_id;
        IF NOT FOUND THEN
          INSERT INTO user_points (user_id, stream_points, general_points)
          VALUES (NEW.user_id, 0, NEW.points);
        END IF;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER increase_points_trigger
      AFTER INSERT ON user_point_audits
      FOR EACH ROW
      EXECUTE FUNCTION increase_points_by_audits();
    """)
  end
end
