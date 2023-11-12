defmodule Web.Instrumenter.ChannelTasks do
  @moduledoc false
  alias Prometheus.Metric.Histogram

  @config Application.fetch_env!(:prometheus, Web.Instrumenter.Phoenix)

  @metric :phoenix_channel_task_duration_microseconds
  @help "Asynchronous channel tasks execution time in microseconds."
  @labels [:channel, :topic, :task, :status]
  @duration_unit Keyword.fetch!(@config, :duration_unit)
  @buckets Keyword.fetch!(@config, :duration_buckets)
  @registry :default

  def setup do
    Histogram.declare(
      name: @metric,
      duration_unit: @duration_unit,
      help: @help,
      labels: @labels,
      buckets: @buckets,
      registry: @registry
    )

    :ok =
      :telemetry.attach(
        "prometheus-channel-task",
        [:billbored, :channel_task, :done],
        &__MODULE__.handle_event/4,
        %{}
      )
  end

  def handle_event([:billbored, :channel_task, :done], %{task: %{name: name}, duration: duration}, %{socket: socket, status: status}, _config) do
    %{channel: channel, topic: topic} = socket
    Histogram.observe([registry: @registry, name: @metric, labels: [channel, normalize_topic(topic), name, status]], duration)
  end

  defp normalize_topic(topic) do
    case Regex.run(~r/^([_\w]+):/, topic) do
      [_, topic_root] -> "#{topic_root}:*"
      _ -> topic
    end
  end
end
