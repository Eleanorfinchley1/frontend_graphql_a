defmodule BillBored.Redix do

  @lock_value "1"

  def start_link(opts) do
    Redix.start_link(opts)
  end

  def child_spec() do
    :poolboy.child_spec(__MODULE__, pool_config(), redix_config())
  end

  def command(command, opts \\ []) do
    :poolboy.transaction(__MODULE__, fn redix_pid ->
      Redix.command(redix_pid, command, opts)
    end)
  end

  def pipeline(commands, opts \\ []) do
    :poolboy.transaction(__MODULE__, fn redix_pid ->
      Redix.pipeline(redix_pid, commands, opts)
    end)
  end

  def script_load(script) do
    case command(["SCRIPT", "LOAD", script]) do
      {:ok, sha} ->
        {:ok, sha}

      error ->
        error
    end
  end

  def script_call(sha, script, args) do
    case command(["EVALSHA", sha, length(args)] ++ args) do
      {:ok, result} ->
        {:ok, result}

      {:error, %Redix.Error{message: "NOSCRIPT No matching script. Please use EVAL."}} ->
        with {:ok, sha} <- script_load(script) do
          IO.inspect(sha)
          command(["EVALSHA", sha, length(args)] ++ args)
        end

      error ->
        error
    end
  end

  def stream_keys(pattern, count \\ 1000) do
    Stream.resource(
      fn -> nil end,
      fn
        nil ->
          {:ok, [cursor, keys]} = command(["SCAN", "0", "MATCH", pattern, "COUNT", "#{count}"])
          {keys, cursor}
        "0" ->
          {:halt, nil}
        cursor ->
          {:ok, [cursor, keys]} = command(["SCAN", cursor, "MATCH", pattern, "COUNT", "#{count}"])
          {keys, cursor}
      end,
      fn _ -> :ok end
    )
  end

  def scan(command, key, opts \\ %{}) do
    cursor = opts[:cursor] || "0"
    count = opts[:count] || 1000

    options = if pattern = opts[:pattern] do
      ["MATCH", pattern, "COUNT", count]
    else
      ["COUNT", count]
    end

    Stream.resource(
      fn -> nil end,
      fn
        nil ->
          {:ok, [cursor, keys]} = command([command, key, cursor] ++ options)
          {keys, cursor}
        "0" ->
          {:halt, nil}
        cursor ->
          {:ok, [cursor, keys]} = command([command, key, cursor] ++ options)
          {keys, cursor}
      end,
      fn _ -> :ok end
    )
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

  defp pool_config() do
    Application.fetch_env!(:billbored, __MODULE__)
    |> Keyword.get(:pool, [])
    |> Keyword.merge(name: {:local, __MODULE__}, worker_module: __MODULE__)
  end

  defp redix_config() do
    Application.fetch_env!(:billbored, __MODULE__)
    |> Keyword.get(:redix, [])
  end
end
