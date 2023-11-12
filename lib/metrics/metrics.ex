defmodule Metrics do
  @moduledoc false

  require Prometheus.Registry

  def setup do
    Prometheus.Registry.register_collector(:prometheus_process_collector)

    Repo.Instrumenter.setup()
    Web.Instrumenter.Phoenix.setup()
    Web.Instrumenter.ChannelTasks.setup()

    :ok =
      :telemetry.attach(
        "prometheus-ecto",
        [:billbored, :repo, :query],
        &Repo.Instrumenter.handle_event/4,
        %{}
      )

    Metrics.Plug.setup()
  end
end
