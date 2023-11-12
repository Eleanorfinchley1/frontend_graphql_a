defmodule Web.MediaView do
  use Web, :view

  alias BillBored.Uploads.File
  alias BillBored.Upload

  def render("index.json", %{files: files}) do
    render_many(files, __MODULE__, "file.json")
  end

  def render("show.json", assigns) do
    case assigns[:file] || assigns[:media] do
      # eventbrite
      "http" <> _rest = url ->
        %{
          results: [
            %{
              media: url,
              media_type: "image",
              media_key: nil,
              media_thumbnail: url,
              owner: nil
            }
          ]
        }

      # eventful
      "//" <> _rest = url ->
        %{
          results: [
            %{
              media: "https:" <> url,
              media_type: "image",
              media_key: nil,
              media_thumbnail: url,
              owner: nil
            }
          ]
        }

      %Upload{} = file ->
        files = [
          %{
            media: File.url({file.media, file}, signed: true),
            media_type: file.media_type,
            media_key: file.media_key,
            media_thumbnail: File.url({file.media, file}, :thumb, signed: true),
            owner: render_one(file.owner, Web.UserView, "min.json")
          }
        ]

        %{
          results: files
        }
    end
  end

  def render("file.json", assigns) do
    render_one(assigns[:file] || assigns[:media], __MODULE__, "show.json")
  end
end
