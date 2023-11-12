defmodule Web.Channels.ChannelTasks do

  @callback start_task(any(), any(), Phoenix.Socket.t()) :: {:ok, Task.t(), Phoenix.Socket.t()} | any()
  @callback handle_task(any(), :completed | :cancelled, any(), Phoenix.Socket.t()) :: {:reply, any(), Phoenix.Socket.t()} | {:noreply, Phoenix.Socket.t()}

  import Phoenix.Channel, only: [socket_ref: 1]
  import Phoenix.Socket, only: [assign: 3]

  defmodule ChannelTask do
    @enforce_keys [:name, :params, :start_time]
    defstruct [:name, :params, :start_time, socket_ref: nil]

    def new(name, params) do
      %__MODULE__{
        name: name,
        params: params,
        start_time: System.monotonic_time()
      }
    end
  end

  defmacro __using__(_) do
    module = __CALLER__.module

    quote do
      @behaviour unquote(__MODULE__)

      def run_exclusive_task(socket, name, params) do
        unquote(__MODULE__).run_exclusive_task(unquote(module), socket, name, params)
      end

      def handle_info_tasks(msg, socket) do
        unquote(__MODULE__).handle_info(unquote(module), msg, socket)
      end
    end
  end

  defp maybe_socket_ref(%Phoenix.Socket{joined: true, ref: ref} = socket) when not is_nil(ref), do: socket_ref(socket)
  defp maybe_socket_ref(%Phoenix.Socket{}), do: nil

  def run_exclusive_task(module, socket, name, params) do
    task = %{ChannelTask.new(name, params) | socket_ref: maybe_socket_ref(socket)}

    if get_in(socket.assigns, [:channel_tasks, name]) do
      debounce_task(module, socket, task)
    else
      start_task(module, socket, task)
    end
  end

  def handle_info(module, {ref, result}, %{assigns: %{channel_tasks: channel_tasks}} = socket) do
    case Map.get(channel_tasks, ref) do
      %ChannelTask{name: name} = task ->
        Process.demonitor(ref, [:flush])

        socket =
          handle_task(module, socket, task, :completed, result)
          |> assign(:channel_tasks, channel_tasks |> Map.delete(ref) |> Map.delete(name))
          |> maybe_start_pending_task(module, name)

        {:noreply, socket}

      _ ->
        Process.demonitor(ref, [:flush])
        {:noreply, socket}
    end
  end

  defp handle_task(module, socket, %ChannelTask{name: name, socket_ref: socket_ref, start_time: start_time} = task, status, payload) do
    new_socket =
      case module.handle_task(name, status, payload, socket) do
        {:reply, reply, new_socket} ->
          if is_nil(socket_ref) do
            raise RuntimeError, "Can't reply from a task without valid socket_ref. Start the task from handle_in to be able to send replies."
          end

          Phoenix.Channel.reply(socket_ref, reply)
          new_socket

        {:noreply, new_socket} ->
          new_socket
      end

    :telemetry.execute(
      [:billbored, :channel_task, :done],
      %{task: task, duration: System.monotonic_time() - start_time},
      %{socket: new_socket, status: status}
    )

    new_socket
  end

  defp debounce_task(module, socket, %ChannelTask{name: name} = task) do
    socket =
      case get_in(socket.assigns, [:channel_pending_tasks, name]) do
        %ChannelTask{params: pending_params} = pending_task ->
          handle_task(module, socket, pending_task, :cancelled, pending_params)

        _ ->
          socket
      end

    new_channel_pending_tasks =
      Access.get(socket.assigns, :channel_pending_tasks, %{})
      |> Map.put(name, task)

    assign(socket, :channel_pending_tasks, new_channel_pending_tasks)
  end

  defp start_task(module, socket, %ChannelTask{name: name, params: params} = task) do
    case module.start_task(name, params, socket) do
      {:ok, %Task{ref: ref}, socket} ->
        channel_tasks = Map.get(socket.assigns, :channel_tasks, %{})
        new_channel_tasks = Map.merge(channel_tasks, %{
          ref => task,
          name => ref
        })
        assign(socket, :channel_tasks, new_channel_tasks)

      _ ->
        socket
    end
  end

  defp maybe_start_pending_task(socket, module, name) do
    case channel_pending_tasks = Map.get(socket.assigns, :channel_pending_tasks) do
      %{^name => pending_task} ->
        start_task(module, socket, pending_task)
        |> assign(:channel_pending_tasks, Map.delete(channel_pending_tasks, name))
      _ ->
        socket
    end
  end
end
