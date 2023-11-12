defmodule BillBored.Workers.UpdateStreamRecordings do
  import Ecto.Query

  require Logger

  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStreams

  @update_interval_shift [minutes: -5]
  @almost_finished_stream_shift [minutes: -170]

  def call(now \\ DateTime.utc_now()) do
    updated_before = Timex.shift(now, @update_interval_shift)
    created_after = Timex.shift(now, @almost_finished_stream_shift)

    Logger.info(
      "Updating recordings of streams updated before #{updated_before} and created after #{
        created_after
      }"
    )

    streams =
      from(s in DropchatStream,
        where:
          s.status == "active" and
            s.inserted_at > ^created_after and
            s.recording_updated_at < ^updated_before and
            fragment("?->>'status' = ANY(?)", s.recording_data, ~w(started in_progress)),
        order_by: [asc: s.recording_updated_at]
      )
      |> Repo.all()

    Logger.info("Total of #{Enum.count(streams)} streams found")

    Enum.each(streams, fn stream ->
      case DropchatStreams.update_recording_status(stream) do
        {:ok, updated_stream} ->
          Logger.debug(
            "Stream #{stream.id} recording status updated: #{updated_stream.recording_data.status}"
          )

          Web.DropchatChannel.notify_stream_event(updated_stream, "stream:recording:updated")

        error ->
          Logger.error("Failed to update stream #{stream.id} recording: #{inspect(error)}")
      end
    end)
  end
end
