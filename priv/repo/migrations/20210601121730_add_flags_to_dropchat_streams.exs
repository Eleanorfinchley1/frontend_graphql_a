defmodule Repo.Migrations.AddFlagsToDropchatStreams do
  use Ecto.Migration

  def change do
    alter(table(:dropchat_streams)) do
      add :flags, :jsonb
    end
  end
end
