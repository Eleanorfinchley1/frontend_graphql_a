defmodule Repo.Migrations.CreateTableEventsAttendees do
  use Ecto.Migration

  def change do
    create table("events_attendees") do
      add :event_id, references("events", on_delete: :delete_all), null: false
      add :user_id, references("accounts_userprofile", on_delete: :delete_all), null: false

      add :status, :string, size: 10

      timestamps()
    end
  end
end
