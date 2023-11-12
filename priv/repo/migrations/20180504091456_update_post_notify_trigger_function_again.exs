defmodule Repo.Migrations.UpdatePostNotifyTriggerFunctionAgain do
  use Ecto.Migration

  def up do
    execute("""
    CREATE OR REPLACE FUNCTION notify_posts_changes() RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
        maybe_user_row RECORD;
        clean_post_row RECORD;
      BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
          current_row := NEW;
        ELSE
          current_row := OLD;
        END IF;

        -- don't broadcast when post.private=true
        IF current_row.private THEN
          RETURN current_row;
        END IF;

        -- TODO clean up post
        -- SELECT id, private, title, body, created, location, post_type
        -- INTO clean_post_row
        -- FROM NEW;

        IF TG_OP = 'INSERT' THEN -- notify about new post insert

          -- fetch post author
          SELECT id, username, first_name, last_name, avatar, avatar_thumbnail
          INTO maybe_user_row
          FROM accounts_userprofile
          WHERE id = current_row.user_id;

          PERFORM pg_notify(
            'posts_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'post', row_to_json(current_row),
              'user', row_to_json(maybe_user_row)
            )::text
          );
        ELSIF TG_OP = 'UPDATE' THEN -- notify about update
          PERFORM pg_notify(
            'posts_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'id', current_row.id,
              'new', row_to_json(NEW),
              'old', row_to_json(OLD)
            )::text
          );
        ELSIF TG_OP = 'DELETE' THEN -- notify about delete
          PERFORM pg_notify(
            'posts_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'id', current_row.id,
              'location', current_row.location,
              'post_type', current_row.post_type
            )::text
          );
        END IF;

        RETURN current_row;
      END;
    $$ LANGUAGE plpgsql;
    """)
  end

  def down do
    execute("""
    CREATE OR REPLACE FUNCTION notify_posts_changes() RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
        maybe_user_row RECORD;
        clean_post_row RECORD;
      BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
          current_row := NEW;
        ELSE
          current_row := OLD;
        END IF;

        -- don't broadcast when post.private=true
        IF current_row.private THEN
          RETURN current_row;
        END IF;

        -- TODO clean up post
        -- SELECT id, private, title, body, created, location, post_type
        -- INTO clean_post_row
        -- FROM NEW;

        IF TG_OP = 'INSERT' THEN -- notify about new post insert

          -- fetch post author
          SELECT id, username, first_name, last_name, avatar, avatar_thumbnail
          INTO maybe_user_row
          FROM accounts_userprofile
          WHERE id = current_row.user_id;

          PERFORM pg_notify(
            'posts_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'post', row_to_json(current_row),
              'user', row_to_json(maybe_user_row)
            )::text
          );
        ELSIF TG_OP = 'UPDATE' THEN -- notify about update
          PERFORM pg_notify(
            'posts_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'id', current_row.id,
              'new', row_to_json(NEW),
              'old', row_to_json(OLD)
            )::text
          );
        ELSIF TG_OP = 'DELETE' THEN -- notify about delete
          PERFORM pg_notify(
            'posts_change',
            json_build_object(
              'table', TG_TABLE_NAME,
              'type', TG_OP,
              'id', current_row.id,
              'location', current_row.location
            )::text
          );
        END IF;

        RETURN current_row;
      END;
    $$ LANGUAGE plpgsql;
    """)
  end
end
