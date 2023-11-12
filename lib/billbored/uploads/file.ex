defmodule BillBored.Uploads.File do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:original, :thumb]

  def storage_dir(_version, {_file, %{media_type: media_type}}) do
    "media/" <> media_type <> "s/"
  end

  def filename(:original, {%{file_name: _filename}, %{media_key: media_key}}) do
    media_key
  end

  def filename(:thumb, {%{file_name: _filename}, %{media_key: media_key}}) do
    media_key <> "thumbnail"
  end
end
