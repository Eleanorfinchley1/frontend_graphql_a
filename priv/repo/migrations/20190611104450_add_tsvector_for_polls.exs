defmodule Repo.Migrations.AddTsvectorForPolls do
  use Ecto.Migration

  def up do
    alter table("polls") do
      add :tsvector, :tsvector
    end

    create(index(:polls, [:tsvector], name: :polls_body_tsvector_index, using: "GIN"))

    execute("""
    CREATE FUNCTION polls_tsvector_update_trigger() RETURNS trigger AS $$
    begin
      new.tsvector := to_tsvector('pg_catalog.english', new.question);
      return new;
    end
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER polls_tsvector_update BEFORE INSERT OR UPDATE
    ON polls FOR EACH ROW EXECUTE PROCEDURE polls_tsvector_update_trigger();
    """)
  end

  def down do
    execute("drop trigger polls_tsvector_update on polls;")
    execute("drop function polls_tsvector_update_trigger();")

    alter table("polls") do
      remove :tsvector
    end
  end
end
