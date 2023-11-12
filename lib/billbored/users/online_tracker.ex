defmodule BillBored.Users.OnlineTracker do
  use GenServer

  require Logger

  alias BillBored.User

  @batch_size 1000
  @auto_store_interval 10_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.send_after(self(), {:store_online_statuses}, @auto_store_interval)
    {:ok, %{online_users: %{}}}
  end

  def update_user_online_status(user) do
    GenServer.cast(__MODULE__, {:update_user_online_status, user})
  end

  @impl true
  def handle_cast({:update_user_online_status, user}, state) do
    new_state =
      state
      |> add_user_online(user)
      |> maybe_store_online_statuses()

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:store_online_statuses}, state) do
    new_state = store_online_statuses(state)
    Process.send_after(self(), {:store_online_statuses}, @auto_store_interval)
    {:noreply, new_state}
  end

  defp add_user_online(%{online_users: online_users} = state, %User{id: user_id}) do
    Map.put(state, :online_users, Map.put(online_users, user_id, Timex.now()))
  end

  defp maybe_store_online_statuses(%{online_users: online_users} = state) do
    if map_size(online_users) > @batch_size do
      store_online_statuses(state)
    else
      state
    end
  end

  defp store_online_statuses(%{online_users: online_users} = state) do
    if map_size(online_users) > 0 do
      BillBored.Users.update_online_statuses(online_users)
    end

    Map.put(state, :online_users, %{})
  end
end
