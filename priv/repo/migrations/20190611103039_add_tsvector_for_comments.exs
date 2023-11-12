defmodule Repo.Migrations.AddTsvectorForComments do
  use Ecto.Migration

  def up do
    alter table("posts_comments") do
      add :tsvector, :tsvector
    end

    create(
      index(:posts_comments, [:tsvector], name: :posts_comments_body_tsvector_index, using: "GIN")
    )

    execute("""
    CREATE FUNCTION posts_comments_tsvector_update_trigger() RETURNS trigger AS $$
    begin
      new.tsvector := to_tsvector('pg_catalog.english', new.body);
      return new;
    end
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER posts_comments_tsvector_update BEFORE INSERT OR UPDATE
    ON posts_comments FOR EACH ROW EXECUTE PROCEDURE posts_comments_tsvector_update_trigger();
    """)
  end

  def down do
    execute("drop trigger posts_comments_tsvector_update on posts_comments;")
    execute("drop function posts_comments_tsvector_update_trigger();")

    alter table("posts_comments") do
      remove :tsvector
    end
  end
end
