defmodule Repo.Migrations.AddDropchatStreamsRecordingData do
  use Ecto.Migration

  def change do
    alter(table(:dropchat_streams)) do
      add :recording_updated_at, :timestamptz
      add :recording_data, :jsonb
    end

    create(index(:dropchat_streams, [:recording_updated_at]))
    create(index(:dropchat_streams, ["(recording_data->'status')"], name: :dropchat_streams_recording_data_status_index))
  end
end
