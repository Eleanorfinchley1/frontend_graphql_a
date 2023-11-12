defmodule Web.MediaController do
  use Web, :controller

  import Ecto.Query
  alias BillBored.Uploads.File
  alias BillBored.{Upload}

  def action(
        %Plug.Conn{
          params: params,
          assigns: %{
            user_id: user_id
          }
        } = conn,
        _opts
      ) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def upload(conn, params, user_id) do
    data = %{
      media: nil,
      media_type: Map.get(params, "media_type", "other"),
      owner_id: user_id
    }

    try do
      file =
        %Upload{}
        |> Upload.changeset(%{
          data
          | media: Map.get(params, "file", [])
        })
        |> Repo.insert()
        |> case do
          {:ok, file} ->
            Repo.preload(file, :owner)

          _ ->
            nil
        end

      render(conn, "show.json", %{file: file})
    rescue
      _ ->
        send_resp(conn, 400, Jason.encode!(%{detail: "invalid request payload"}, pretty: true))
    end
  end

  def get_links(conn, params, _user_id) do
    case params["media_file_keys"] do
      media_file_keys when is_list(media_file_keys) ->
        files =
          Upload
          |> where([m], m.media_key in ^media_file_keys)
          |> preload(:owner)
          |> Repo.all()

        render(conn, "index.json", %{files: files})

      _ ->
        conn
        |> put_status(400)
        |> json(%{details: "media_file_keys should be a list"})
    end
  end

  def delete(conn, %{"key" => media_key}, user_id) do
    Upload
    |> where([m], m.media_key == ^media_key)
    |> Repo.one()
    |> case do
      nil ->
        conn
        |> put_status(404)
        |> json(%{details: "Upload doesn't exist"})

      %Upload{owner_id: ^user_id} = file ->
        {:ok, file} = Repo.delete(file)
        File.delete({file.media, file})
        send_resp(conn, 204, [])

      %Upload{} ->
        conn
        |> put_status(403)
        |> json(%{details: "Only the owner is allowed to delete this item!"})
    end
  end
end
