defmodule Repo.Migrations.DropMediaFileKeys do
  use Ecto.Migration

  defp drop_media_file_keys(table) do
    alter table(table) do
      remove :media_file_keys, {:array, :string}, null: false
    end
  end

  def change do
    drop_media_file_keys(:chat_message)
    drop_media_file_keys(:events)
    drop_media_file_keys(:polls_items)
    drop_media_file_keys(:posts)
    drop_media_file_keys(:posts_comments)
  end
end
