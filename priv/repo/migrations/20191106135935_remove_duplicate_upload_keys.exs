defmodule Repo.Migrations.RemoveDuplicateUploadKeys do
  use Ecto.Migration
  import Ecto.Query

  def up do
    uniq_media_file_keys("events")
    uniq_media_file_keys("posts")
    uniq_media_file_keys("chat_message")
    uniq_media_file_keys("polls_items")
    uniq_media_file_keys("posts_comments")
  end

  defp uniq_media_file_keys(table) do
    table
    |> select([r], {r.id, r.media_file_keys})
    |> Repo.all()
    |> Enum.map(fn {resource_id, media_file_keys} ->
      table
      |> where(id: ^resource_id)
      |> Repo.update_all(set: [media_file_keys: Enum.uniq(media_file_keys)])
    end)
  end

  def down do
    raise "not implemented"
  end
end
