defmodule BillBored.Livestreams.InMemory do
  use GenServer

  # TODO replace with phoenix.tracker

  @table __MODULE__

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec exists?(Ecto.UUID.t()) :: boolean
  def exists?(<<livestream_id::36-bytes>>) do
    case :ets.lookup(@table, livestream_id) do
      [_livestream] -> true
      [] -> false
    end
  end

  @spec get(:viewers_count, Ecto.UUID.t()) :: non_neg_integer | nil
  def get(:viewers_count, <<livestream_id::36-bytes>>) do
    case :ets.lookup(@table, livestream_id) do
      [{^livestream_id, viewers_count}] -> viewers_count
      [] -> nil
    end
  end

  @spec start(BillBored.Livestream.t()) :: boolean
  def start(%BillBored.Livestream{id: <<livestream_id::36-bytes>>}) do
    GenServer.call(__MODULE__, {:create, livestream_id})
  end

  @spec publish(Ecto.UUID.t()) :: :ok
  def publish(<<livestream_id::36-bytes>>) do
    %BillBored.Livestream{location: %BillBored.Geo.Point{} = livestream_location} =
      livestream = BillBored.Livestreams.change_status(livestream_id, true)

    rendered_livestream = Web.LivestreamView.render("livestream.json", %{livestream: livestream})

    message = %{
      location: livestream_location,
      payload: rendered_livestream
    }

    # TODO why?
    if unquote(Mix.env() == :test) do
      Web.Endpoint.broadcast("livestreams", "livestream:new", message)
    else
      spawn(fn ->
        :timer.sleep(:timer.seconds(5))
        Web.Endpoint.broadcast("livestreams", "livestream:new", message)
      end)
    end

    :ok
  end

  @spec publish_done(Ecto.UUID.t()) :: :ok
  def publish_done(<<livestream_id::36-bytes>>) do
    %BillBored.Livestream{location: %BillBored.Geo.Point{} = livestream_location} =
      BillBored.Livestreams.change_status(livestream_id, false)

    message = %{
      payload: %{"id" => livestream_id},
      location: livestream_location
    }

    GenServer.call(__MODULE__, {:delete, livestream_id})
    Web.Endpoint.broadcast("livestreams", "livestream:over", message)
    Web.Endpoint.broadcast("livestream:#{livestream_id}", "livestream:over", %{})

    :ok
  end

  @spec update_viewers_count(Ecto.UUID.t(), integer) :: result :: integer
  def update_viewers_count(<<livestream_id::36-bytes>>, diff) when is_integer(diff) do
    GenServer.call(__MODULE__, {:update_viewers_count, livestream_id, diff})
  end

  def init(_opts) do
    @table = :ets.new(@table, [:named_table])

    Enum.each(BillBored.Livestreams.list_active(), fn %BillBored.Livestream{
                                                        id: <<livestream_id::36-bytes>>
                                                      } ->
      send(self(), {:create, livestream_id})
    end)

    {:ok, []}
  end

  def handle_call({:create, <<livestream_id::36-bytes>>}, _from, state) do
    {:reply, :ets.insert_new(@table, {livestream_id, 0}), state}
  end

  def handle_call({:delete, <<livestream_id::36-bytes>>}, _from, state) do
    {:reply, :ets.delete(@table, livestream_id), state}
  end

  def handle_call({:update_viewers_count, <<livestream_id::36-bytes>>, diff}, _from, state) do
    {:reply, :ets.update_counter(@table, livestream_id, diff), state}
  end

  def handle_info({:create, <<livestream_id::36-bytes>>}, state) do
    :ets.insert_new(@table, {livestream_id, 0})
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # TODO add ttl, clean up stale streams
end
