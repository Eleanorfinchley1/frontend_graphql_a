defmodule Repo.Migrations.ChangeUploadsPrimaryKey do
  use Ecto.Migration

  def up do
    drop constraint(:upload_fileupload, :upload_fileupload_pkey)
    drop constraint(:upload_fileupload, :upload_fileupload_media_key_key)
    execute "ALTER TABLE upload_fileupload ADD PRIMARY KEY (media_key);"

    alter table(:upload_fileupload) do
      remove :id, :id
    end
  end

  def down do
    raise "not implemented"
  end
end
