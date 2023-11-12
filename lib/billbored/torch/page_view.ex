defmodule BillBored.Torch.PageView do
  @moduledoc false

  alias Torch.PageView, as: TorchPageView

  def body_classes(%Plug.Conn{private: %{phoenix_action: :index_for_review}}), do: "torch-index"
  def body_classes(%Plug.Conn{private: %{phoenix_action: :pre_notify}}), do: "torch-index"
  def body_classes(conn), do: TorchPageView.body_classes(conn)
end
