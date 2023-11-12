defmodule Repo.Migrations.CreateDropchatElevatedPrivileges do
  use Ecto.Migration

  def change do
    create table(:dropchat_elevated_privileges) do
      add(
        :user_id,
        references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all),
        null: false
      )

      add(
        :dropchat_id,
        references(:chat_room, on_delete: :delete_all, on_update: :update_all),
        null: false
      )

      timestamps(updated_at: false)
    end

    create(index(:dropchat_elevated_privileges, [:user_id]))
    create(index(:dropchat_elevated_privileges, [:dropchat_id]))
    create(unique_index(:dropchat_elevated_privileges, [:dropchat_id, :user_id]))
  end
end
