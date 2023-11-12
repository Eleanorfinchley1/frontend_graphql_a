defmodule Repo.Migrations.CreateChatRoomTitleTrgmIndex do
  use Ecto.Migration

  def up do
    execute(
      "create index chat_room_title_trgm_index on chat_room using gin (title gin_trgm_ops);"
    )
  end

  def down do
    execute("drop index chat_room_title_trgm_index;")
  end
end
