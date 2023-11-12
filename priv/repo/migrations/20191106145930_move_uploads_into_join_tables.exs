defmodule Repo.Migrations.MoveUploadsIntoJoinTables do
  use Ecto.Migration
  import Ecto.Query

  def up do
    [
      {"message_uploads", "chat_message", :message_id},
      {"event_uploads", "events", :event_id},
      {"poll_item_uploads", "polls_items", :poll_item_id},
      {"post_uploads", "posts", :post_id},
      {"comment_uploads", "posts_comments", :comment_id}
    ]
    |> Enum.each(fn {resource_table, join_table, resource_key} ->
      Repo.insert_all(
        resource_table,
        from_media_file_keys_to_join_table_data(join_table, resource_key)
      )
    end)
  end

  defp from_media_file_keys_to_join_table_data(table, resource_key) do
    table
    |> select([r], {r.id, r.media_file_keys})
    |> Repo.all()
    |> Enum.flat_map(fn {resource_id, media_file_keys} ->
      media_file_keys
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn key -> [{resource_key, resource_id}, {:upload_key, key}] end)
    end)
  end

  def down do
    [
      {"message_uploads", "chat_message", :message_id},
      {"event_uploads", "events", :event_id},
      {"poll_item_uploads", "polls_items", :poll_item_id},
      {"post_uploads", "posts", :post_id},
      {"comment_uploads", "posts_comments", :comment_id}
    ]
    |> Enum.each(fn {join_table, resource_table, resource_key} ->
      from_join_table_to_media_file_keys(join_table, resource_table, resource_key)
    end)
  end

  defp from_join_table_to_media_file_keys(join_table, resource_table, key) do
    select_fields = [key, :upload_key]

    join_table
    |> select([r], ^select_fields)
    |> Repo.all()
    |> Enum.group_by(
      fn {resource_id, _upload_key} -> resource_id end,
      fn {_resource_id, upload_key} -> upload_key end
    )
    |> Enum.each(fn {resource_id, media_file_keys} ->
      resource_table
      |> where(id: ^resource_id)
      |> Repo.update_all(set: [media_file_keys: media_file_keys])
    end)
  end
end
