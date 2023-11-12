defmodule Repo.Migrations.AlterChatMessagesPrivatePostIdFk do
  use Ecto.Migration
  import Ecto.Query

  def up do
    drop_if_exists constraint(
                     :chat_message,
                     "chat_message_private_post_id_6d25fa85_fk_pst_post_id"
                   )

    drop_if_exists constraint(:chat_message, "chat_message_private_post_id_fkey")
    "chat_message" |> where([m], not is_nil(m.private_post_id)) |> Repo.delete_all()

    alter table(:chat_message) do
      modify :private_post_id, references(:posts, on_delete: :delete_all)
    end
  end

  def down do
    drop constraint(:chat_message, "chat_message_private_post_id_fkey")
    "chat_message" |> where([m], not is_nil(m.private_post_id)) |> Repo.delete_all()

    alter table(:chat_message) do
      modify :private_post_id, references(:pst_post, on_delete: :delete_all)
    end
  end
end
