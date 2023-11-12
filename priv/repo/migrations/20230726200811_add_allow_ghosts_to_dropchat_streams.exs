defmodule Repo.Migrations.AddAllowGhostsToDropchatStreams do
  use Ecto.Migration

  def change do
    alter table(:dropchat_streams) do
      add :allow_ghosts, :boolean, default: false
    end
  end
end
