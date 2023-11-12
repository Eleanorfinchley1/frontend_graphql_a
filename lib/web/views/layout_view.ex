defmodule Web.LayoutView do
  use Web, :view

  def render("success.json", %{result: result}) do
    %{"success" => true, "result" => result}
  end
end
