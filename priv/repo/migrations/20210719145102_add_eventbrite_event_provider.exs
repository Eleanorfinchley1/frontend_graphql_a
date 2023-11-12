defmodule Repo.Migrations.AddEventbriteEventProvider do
  use Ecto.Migration
  @disable_ddl_transaction true

  def up do
    execute("ALTER TYPE event_provider ADD VALUE 'eventbrite' AFTER 'allevents'")
  end

  def down do
  end
end
