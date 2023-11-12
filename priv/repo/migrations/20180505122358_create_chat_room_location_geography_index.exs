defmodule Repo.Migrations.CreateChatRoomLocationGeographyIndex do
  use Ecto.Migration

  def up do
    execute(
      "CREATE INDEX chat_room_location_id2 ON chat_room USING gist (((location)::geography));"
    )
  end

  def down do
    execute("DROP INDEX chat_room_location_id2;")
  end
end
