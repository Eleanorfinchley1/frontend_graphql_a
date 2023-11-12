defmodule Web.MessageChannel do
  use Web, :channel

  def join("messages", _params, socket) do
    {:ok, socket}
  end
end
