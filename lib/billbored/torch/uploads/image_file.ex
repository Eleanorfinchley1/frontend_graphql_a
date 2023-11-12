defmodule BillBored.Torch.Uploads.ImageFile do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)

  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end

  def storage_dir(_version, {_file, %{media_type: media_type}}) do
    root = Application.get_env(:arc, :storage_dir, "media")
    Path.join(root, media_type <> "s") <> "/"
  end

  def filename(:original, {%{file_name: _filename}, %{media_key: media_key}}) do
    media_key
  end
end
