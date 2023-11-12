defmodule Repo.Migrations.AddLastAudienceCountToDropchatStreams do
  use Ecto.Migration

  def change do
    alter table(:dropchat_streams) do
      add :last_audience_count, :integer
    end
  end
end
