defmodule BillBored.Workers.ExpireStreamRecordings do
  import Ecto.Query

  require Logger

  alias BillBored.Chat.Room.DropchatStream

  @expired_recordings_shift [days: -7]

  def call(now \\ DateTime.utc_now()) do
    created_before = Timex.shift(now, @expired_recordings_shift)
    updated_at = Timex.now()

    Logger.info("Expiring stream recordings created before #{created_before}")

    query =
      from(s in DropchatStream,
        where:
          s.status == "finished" and
            s.inserted_at < ^created_before and
            fragment("?->>'status' = ANY(?)", s.recording_data, ~w(started in_progress finished)),
        update: [
          set: [
            recording_updated_at: ^updated_at,
            recording_data:
              fragment("jsonb_set(?, ?::text[], ?)", s.recording_data, ["status"], "\"expired\"")
          ]
        ]
      )

    {updated, _} = Repo.update_all(query, [])
    Logger.info("Expired #{updated} stream recordings")
  end
end
