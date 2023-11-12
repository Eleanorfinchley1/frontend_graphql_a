defmodule BillBored.CachedPosts.Server do
  use GenServer

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{pending_requests: 0}}
  end

if Mix.env() == :test do
  def notify(), do: :ok
else
  def notify() do
    GenServer.call(__MODULE__, {:notify})
  end
end

  @impl true
  def handle_call({:notify}, _from, %{task_ref: _ref, pending_requests: pending_requests} = state) do
    {:reply, :ok, Map.put(state, :pending_requests, pending_requests + 1)}
  end

  def handle_call({:notify}, _from, state) do
    new_state = run_task(state)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info({ref, _result}, %{task_ref: ref} = state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, _, _pid, _reason}, %{task_ref: ref, pending_requests: pending_requests} = state) do
    new_state = if pending_requests > 0 do
      run_task(state)
    else
      Map.delete(state, :task_ref)
    end

    {:noreply, new_state}
  end

  defp run_task(%{pending_requests: pending_requests} = state) do
    Logger.debug("Running BillBored.CachedPosts.invalidate_state with #{pending_requests} pending requests.")

    %Task{ref: ref} = Task.async(fn ->
      {duration, result} = Timex.Duration.measure(fn ->
        BillBored.CachedPosts.invalidate_stale()
      end)

      Logger.debug("Finished cached posts invalidation in #{Timex.Duration.to_string(duration)}: #{inspect(result)}")
      result
    end)

    state
    |> Map.put(:task_ref, ref)
    |> Map.put(:pending_requests, 0)
  end
end
