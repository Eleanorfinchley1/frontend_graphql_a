defmodule Web.Instrumenter.Phoenix do
  @moduledoc false
  use Prometheus.PhoenixInstrumenter

  def label_value(:topic, %{topic: topic}) when is_binary(topic) do
    case Regex.run(~r/^([_\w]+):/, topic) do
      [_, topic_root] -> "#{topic_root}:*"
      _ -> topic
    end
  end

  def label_value(:topic, _conn) do
    nil
  end
end
