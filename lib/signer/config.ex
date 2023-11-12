defmodule Signer.Config do
  @moduledoc """
  Stores config (like google app creds) in an ets table
  """

  use GenServer

  @table __MODULE__

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec get(atom) :: term | nil
  def get(key) when is_atom(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> value
      [] -> nil
    end
  end

  @spec get!(atom) :: term | no_return
  def get!(key) when is_atom(key) do
    case :ets.lookup(@table, key) do
      [{^key, value}] -> value
      [] -> raise("no value for #{key} found")
    end
  end

  @spec put(atom, term) :: true
  def put(key, value) when is_atom(key) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  @spec delete(atom) :: true
  def delete(key) when is_atom(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  @impl true
  def init(_opts) do
    @table = :ets.new(@table, [:named_table, :set, :protected])
    {:ok, [], {:continue, :populate_config}}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    {:reply, :ets.insert(@table, {key, value}), state}
  end

  def handle_call({:delete, key}, _from, state) do
    {:reply, :ets.delete(@table, key), state}
  end

  @impl true
  def handle_continue(:populate_config, state) do
    :code.priv_dir(:billbored)
    # TODO store account.json in k8s secrets
    |> Path.join("account.json")
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(fn {key, value} ->
      key = :erlang.binary_to_atom(key, :latin1)
      :ets.insert(@table, {key, value})
    end)

    private_key = get!(:private_key)

    :ets.insert(
      @table,
      {:private_key_record,
       private_key
       |> :public_key.pem_decode()
       |> hd()
       |> :public_key.pem_entry_decode()}
    )

    {:noreply, state}
  end
end
