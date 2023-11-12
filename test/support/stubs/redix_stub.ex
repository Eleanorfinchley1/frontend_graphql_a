defmodule BillBored.Stubs.Redix do
  use GenServer

  @process_key :redix_stub_pid
  @lock_value "1"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  def use(pid) do
    Process.put(@process_key, pid)
  end

  def use_global(pid) do
    Application.put_env(:billbored, __MODULE__, pid: pid)
  end

  defp with_redix_pid(fun) do
    case Process.get(@process_key) do
      nil ->
        case Application.get_env(:billbored, __MODULE__, [pid: nil])[:pid] do
          nil ->
            raise "Redix stub PID isn't set neither for process #{inspect(self())} nor globally"

          pid ->
            fun.(pid)
        end

      pid ->
        fun.(pid)
    end
  end

  def command(command, opts \\ []) do
    with_redix_pid(fn pid ->
      GenServer.call(pid, {:command, command, opts})
    end)
  end

  def pipeline(commands, opts \\ []) do
    with_redix_pid(fn pid ->
      GenServer.call(pid, {:pipeline, commands, opts})
    end)
  end

  def stream_keys(pattern, _count \\ 1000) do
    {:ok, keys} = command(["KEYS", "*"])
    re = Regex.compile!(String.replace(pattern, "*", ".*"))
    Stream.filter(keys, fn key -> Regex.match?(re, key) end)
  end

  def with_lock(key, ttl, fun) when is_function(fun) and is_integer(ttl) do
    try do
      with :ok <- lock(key, ttl) do
        fun.()
      end
    after
      unlock(key)
    end
  end

  def lock(key, ttl) when is_integer(ttl) do
    case command(["SET", key, @lock_value, "EX", ttl, "NX"]) do
      {:ok, "OK"} -> :ok
      {:ok, nil} -> {:error, :locked}
      {:error, error} -> {:error, error}
    end
  end

  def unlock(key) do
    case command(["DEL", key]) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  @impl true
  def handle_call({:command, command, _opts}, _ref, state) do
    {new_state, [result]} = apply_commands(state, [command])
    {:reply, {:ok, result}, new_state}
  end

  def handle_call({:pipeline, commands, _opts}, _ref, state) do
    {new_state, results} = apply_commands(state, commands)
    {:reply, {:ok, results}, new_state}
  end

  defp apply_commands(state, commands), do: do_apply_commands(state, commands, [])

  defp do_apply_commands(state, [], results), do: {state, Enum.reverse(results)}

  defp do_apply_commands(state, [["GET", key] | rest], results) do
    value = Map.get(state, key)
    do_apply_commands(state, rest, [value | results])
  end

  defp do_apply_commands(state, [["SCAN", cursor, "MATCH", pattern] | rest], results) do
    [keys] = [Map.keys(state) | results]
    re = Regex.compile!(String.replace(pattern, "*", ".*"))
    result = Enum.filter(keys, fn key -> Regex.match?(re, key) end)
    do_apply_commands(state, rest, [[0, result ++ results]])
  end

  defp do_apply_commands(state, [["TTL", key] | rest], results) do
    value = :rand.uniform(100)
    do_apply_commands(state, rest, [value | results])
  end

  defp do_apply_commands(state, [["DEL" | keys] | rest], results) do
    keys = if is_list(keys) do
      keys
    else
      [keys]
    end

    {new_state, count} = Enum.reduce(keys, {state, 0}, fn key, {state, count} ->
      case state do
        %{^key => _} -> {Map.delete(state, key), count + 1}
        _ -> {state, count}
      end
    end)
    do_apply_commands(new_state, rest, [count | results])
  end

  defp do_apply_commands(state, [["SET", key, value] | rest], results) do
    new_state = Map.put(state, to_string(key), to_string(value))
    do_apply_commands(new_state, rest, ["OK" | results])
  end

  defp do_apply_commands(state, [["SETEX", key, _ttl, value] | rest], results) do
    new_state = Map.put(state, to_string(key), to_string(value))
    do_apply_commands(new_state, rest, ["OK" | results])
  end

  defp do_apply_commands(state, [["SET", key, value, "EX", _ttl, "NX"] | rest], results) do
    new_state = Map.put(state, to_string(key), to_string(value))
    do_apply_commands(new_state, rest, ["OK" | results])
  end

  defp do_apply_commands(state, [["KEYS", "*"] | rest], results) do
    do_apply_commands(state, rest, [Map.keys(state) | results])
  end

  defp do_apply_commands(_state, [["FLUSHALL"] | rest], results) do
    do_apply_commands(%{}, rest, ["OK" | results])
  end

  defp do_apply_commands(state, [["EXPIRE", _key, _ttl] | rest], results) do
    do_apply_commands(state, rest, [1 | results])
  end

  defp do_apply_commands(state, [["EXISTS", key] | rest], results) do
    result = if Map.has_key?(state, key), do: 1, else: 0
    do_apply_commands(state, rest, [result | results])
  end

  defp do_apply_commands(state, [["ZADD", key, score, value] | rest], results) do
    {result, new_zset} = zadd(state[to_string(key)], score, value)
    new_state = Map.put(state, to_string(key), new_zset)
    do_apply_commands(new_state, rest, [result | results])
  end

  defp do_apply_commands(state, [["ZREM", key, value] | rest], results) do
    {result, new_zset} = zrem(state[to_string(key)], value)
    new_state = Map.put(state, to_string(key), new_zset)
    do_apply_commands(new_state, rest, [result | results])
  end

  defp do_apply_commands(state, [["ZCOUNT", key, min, max] | rest], results) do
    result = zcount(state[to_string(key)], min, max)
    do_apply_commands(state, rest, [result | results])
  end

  defp zadd(zset, score_str, value) do
    {score, ""} = Float.parse(score_str)

    new_zset =
      [{score, value} | Enum.reject(zset || [], fn {_, v} -> v == value end)]
      |> Enum.sort_by(fn {score, _} -> score end)

    {score, new_zset}
  end

  defp zrem(zset, value) do
    new_zset = Enum.reject(zset || [], fn {_, v} -> v == value end)
    {1, new_zset}
  end

  defp zcount(zset, min_str, max_str) do
    {min, ""} = Float.parse(min_str)
    {max, ""} = Float.parse(max_str)

    Enum.reduce(zset || [], 0, fn {score, _}, acc ->
      if score >= min && score <= max do
        acc + 1
      else
        acc
      end
    end)
  end
end
