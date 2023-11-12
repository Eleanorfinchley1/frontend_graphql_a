defmodule Repo.Migrations.CompatDropContraintsChatRoom do
  use Ecto.Migration

  def change do
    drop constraint(:chat_room, "chat_room_place_id_6f634c49_fk_places_place_id")
  end
end
