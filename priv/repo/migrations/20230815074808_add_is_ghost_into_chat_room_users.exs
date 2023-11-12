defmodule Repo.Migrations.AddIsGhostIntoDropchatStreamSpeakers do
  use Ecto.Migration

  def change do
    alter table(:dropchat_streams_speakers) do
      add :is_ghost, :boolean, default: false
    end
  end
end
