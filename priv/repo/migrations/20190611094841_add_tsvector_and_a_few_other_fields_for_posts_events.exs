defmodule Repo.Migrations.AddTsvectorAndAFewOtherFieldsForPostsEvents do
  use Ecto.Migration

  def up do
    rename table("posts_events"), to: table("events")

    alter table("events") do
      add :body, :text

      add :price, :float
      add :currency, :string, size: 40

      add :buy_ticket_link, :string, size: 512

      remove :date
      add :begin_date, :utc_datetime_usec, null: false
      add :end_date, :utc_datetime_usec

      add :child_friendly, :boolean, default: false

      add :place_id, references("places")

      add :tsvector, :tsvector
    end

    create(index(:events, [:tsvector], name: :events_body_tsvector_index, using: "GIN"))

    execute("""
    CREATE FUNCTION events_tsvector_update_trigger() RETURNS trigger AS $$
    begin
      new.tsvector := to_tsvector('pg_catalog.english', new.body);
      return new;
    end
    $$ LANGUAGE plpgsql;
    """)

    execute("""
    CREATE TRIGGER events_tsvector_update BEFORE INSERT OR UPDATE
    ON events FOR EACH ROW EXECUTE PROCEDURE events_tsvector_update_trigger();
    """)
  end

  def down do
    execute("drop trigger events_tsvector_update on events;")
    execute("drop function events_tsvector_update_trigger();")

    alter table("events") do
      remove :body

      remove :price
      remove :buy_ticket_link

      add :date, :utc_datetime_usec, null: false
      remove :begin_date
      remove :end_date

      remove :child_friendly
      remove :currency
      remove :place_id
      remove :tsvector
    end

    rename table("events"), to: table("posts_events")
  end
end
