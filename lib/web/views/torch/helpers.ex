defmodule Web.Torch.Helpers do
  def float(val) do
    :erlang.float_to_binary(val, [:compact, {:decimals, 10}])
  end

  def location(%BillBored.Geo.Point{long: lon, lat: lat}) do
    "#{float(lat)}, #{float(lon)}"
  end

  def image_url(upload, version, opts \\ [signed: true]) do
    case BillBored.Torch.Uploads.ImageFile.url({upload.media, upload}, version, opts) do
      "/priv/uploads/" <> url -> "/uploads/#{url}"
      url -> url
    end
  end

  def datetime(nil), do: nil

  def datetime(datetime) do
    Timex.format!(datetime, "{ISO:Extended:Z}")
  end
end
