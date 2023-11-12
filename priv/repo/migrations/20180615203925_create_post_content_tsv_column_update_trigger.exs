defmodule Repo.Migrations.CreatePostContentTsvColumnUpdateTrigger do
  use Ecto.Migration

  def up do
    execute("""
    CREATE FUNCTION pst_post_tsv_update_trigger() RETURNS trigger AS $$
    begin
      new.tsv := to_tsvector('pg_catalog.english', new.body);
      return new;
    end
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER pst_post_tsv_update BEFORE INSERT OR UPDATE
    ON pst_post FOR EACH ROW EXECUTE PROCEDURE pst_post_tsv_update_trigger();
    """)
  end

  def down do
    execute("drop trigger pst_post_tsv_update on pst_post;")
    execute("drop function pst_post_tsv_update_trigger();")
  end
end
