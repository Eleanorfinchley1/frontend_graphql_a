defmodule Web.DeviceView do
  use Web, :view

  alias Web.ViewHelpers

  def render("index.json", %{conn: conn, data: devices}) do
    ViewHelpers.index(conn, devices, __MODULE__)
  end

  def render("show.json", %{device: device}) do
    render_one(device, __MODULE__, "page.json")
  end

  def render("page.json", %{device: device}) do
    %{
      id: device.id,
      token: device.token,
      platform: device.platform,
      user: render_one(device.user, Web.UserView, "user.json")
    }
  end
end
