defmodule BillBored.Chat.DropchatUpdateServer do
  use GenServer

  alias BillBored.Chat.Room.DropchatStream
  alias BillBored.Chat.Room.DropchatStreams

  require Logger

  @update_interval 20_000
  @chunk_size 100

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :update_dropchats, @update_interval)
    {:ok, %{}}
  end

  @impl true
  def handle_info(:update_dropchats, state) do
    updated_count =
        DropchatStreams.list_active()
        |> Enum.chunk_every(@chunk_size)
        |> Enum.reduce(0, fn streams, acc ->
            updates =
              streams
              |> Enum.map(fn stream ->
                stream
                |> Map.take([:id, :key, :dropchat_id, :admin_id, :status, :inserted_at])
                |> Map.put(:last_audience_count, DropchatStreams.live_audience_count(stream))
              end)

            {updated, _} = Repo.insert_all(DropchatStream, updates, on_conflict: {:replace, [:last_audience_count]}, conflict_target: [:id])
            acc + updated
        end)

    Logger.info("#{inspect(__MODULE__)}: updated #{updated_count} dropchat streams")
    Process.send_after(self(), :update_dropchats, @update_interval)

    {:noreply, state}
  end
end
