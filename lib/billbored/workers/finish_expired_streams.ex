defmodule BillBored.Workers.FinishExpiredStreams do
  import Ecto.Query

  require Logger

  alias BillBored.UserPoint
  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStreams

  @points_per_minute get_in(Application.get_env(:billbored, BillBored.UserPoints), [:points_per_minute])

  def call(now \\ DateTime.utc_now()) do
    after_created = %{now | second: 0, minute: 0, hour: 0}
    streams =
      from(s in DropchatStream,
        left_join: up in UserPoint,
        on: s.admin_id == up.user_id,
        join: dm in subquery(
          from d in DropchatStream,
            where: d.status == "finished" and d.finished_at >= ^after_created or d.status == "active",
            select: %{
              admin_id: d.admin_id,
              minutes: fragment("coalesce(sum(CEIL(EXTRACT(EPOCH FROM AGE(coalesce(?, ?), ?)) / 60))::integer, 0)", d.finished_at, ^now, d.inserted_at)
            },
            group_by: d.admin_id
        ),
        on: s.admin_id == dm.admin_id and dm.minutes >= ^DropchatStreams.daily_free_minutes(),
        where: s.status == "active",
        where: is_nil(up.stream_points) or
          fragment("LEAST(CEIL(EXTRACT(EPOCH FROM AGE(?, ?)) / 60), ? - ?)::integer", ^now, s.inserted_at, dm.minutes, ^DropchatStreams.daily_free_minutes())
            >= fragment("CEIL(? / ?)::integer", up.stream_points, ^@points_per_minute),
        order_by: [asc: s.inserted_at]
      )
      |> preload(:dropchat)
      |> Repo.all()

    Logger.info("Total of #{Enum.count(streams)} streams spending points fully")

    Enum.each(streams, fn stream ->
      case DropchatStreams.finish(stream) do
        {:ok, updated_stream} ->
          Logger.debug("Stream #{stream.id} has been finished")
          Web.DropchatChannel.notify_stream_event(updated_stream, "stream:recording:finished")

        error ->
          Logger.error("Failed to finish stream #{stream.id}: #{inspect(error)}")
      end
    end)
  end
end
