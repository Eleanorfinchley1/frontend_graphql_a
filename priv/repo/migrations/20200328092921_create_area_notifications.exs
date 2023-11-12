defmodule Repo.Migrations.CreateAreaNotifications do
  use Ecto.Migration

  def change do
    create(table(:area_notifications)) do
      add :owner_id, references(:accounts_userprofile)
      add :title, :string
      add :message, :text, null: false
      add :location, :geometry, null: false
      add :radius, :float, null: false
      add :logo_media_key, references(:upload_fileupload, type: :string, column: :media_key)
      add :image_media_key, references(:upload_fileupload, type: :string, column: :media_key)
      add :expires_at, :utc_datetime_usec
      add :receivers_count, :integer

      timestamps()
    end
  end
end
