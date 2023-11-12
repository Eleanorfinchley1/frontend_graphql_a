defmodule Repo.Migrations.CreateEventProviderType do
  use Ecto.Migration

  def up do
    execute("CREATE TYPE event_provider AS ENUM ('eventful', 'meetup', 'allevents')")
  end

  def down do
    execute("DROP TYPE event_provider")
  end
end
