defmodule Repo.Migrations.CreateDropchatBans do
  use Ecto.Migration

  def change do
    create table(:dropchat_bans) do
      add :dropchat_id, references(:chat_room, on_delete: :delete_all, on_update: :update_all), null: false
      add :admin_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), null: false
      add :banned_user_id, references(:accounts_userprofile, on_delete: :delete_all, on_update: :update_all), null: false

      timestamps(updated_at: false)
    end

    create(unique_index(:dropchat_bans, [:dropchat_id, :banned_user_id]))
  end
end
