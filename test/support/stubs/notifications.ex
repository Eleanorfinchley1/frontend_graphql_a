defmodule Billbored.Stubs.Notifications do
  def process_dropchat_stream_started(args) do
    Phoenix.PubSub.broadcast!(ExUnit.PubSub, "stubs:notifications", {:process_dropchat_stream_started, [args]})
    :ok
  end

  def process_dropchat_stream_pinged(args) do
    Phoenix.PubSub.broadcast!(ExUnit.PubSub, "stubs:notifications", {:process_dropchat_stream_pinged, [args]})
    :ok
  end
end
