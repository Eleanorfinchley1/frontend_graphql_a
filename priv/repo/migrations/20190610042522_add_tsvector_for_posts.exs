defmodule Repo.Migrations.AddTsvectorForPosts do
  use Ecto.Migration

  def up do
    alter table("posts") do
      add :tsvector, :tsvector
    end

    create(index(:posts, [:tsvector], name: :posts_body_tsvector_index, using: "GIN"))

    execute("""
    CREATE FUNCTION posts_tsvector_update_trigger() RETURNS trigger AS $$
    begin
      new.tsvector := to_tsvector('pg_catalog.english', new.body);
      return new;
    end
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER posts_tsvector_update BEFORE INSERT OR UPDATE
    ON posts FOR EACH ROW EXECUTE PROCEDURE posts_tsvector_update_trigger();
    """)
  end

  def down do
    execute("drop trigger posts_tsvector_update on posts;")
    execute("drop function posts_tsvector_update_trigger();")

    alter table("posts") do
      remove :tsvector
    end
  end
end
