defmodule Repo.Migrations.AddUniqueEventAttandeesIndex do
  use Ecto.Migration

  def change do
    create unique_index(:events_attendees, [:event_id, :user_id])
  end
end
