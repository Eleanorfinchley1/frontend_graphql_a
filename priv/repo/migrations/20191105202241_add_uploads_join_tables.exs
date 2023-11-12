defmodule Repo.Migrations.AddUploadsJoinTables do
  use Ecto.Migration

  @reference_opts [on_delete: :delete_all, on_update: :update_all]
  @upload_reference_opts @reference_opts ++ [column: :media_key, type: :string]

  def change do
    create table(:message_uploads, primary_key: false) do
      add :message_id, references(:chat_message, @reference_opts), primary_key: true
      add :upload_key, references(:upload_fileupload, @upload_reference_opts), primary_key: true
    end

    create table(:event_uploads, primary_key: false) do
      add :event_id, references(:events, @reference_opts), primary_key: true
      add :upload_key, references(:upload_fileupload, @upload_reference_opts), primary_key: true
    end

    create table(:poll_item_uploads, primary_key: false) do
      add :poll_item_id, references(:polls_items, @reference_opts), primary_key: true
      add :upload_key, references(:upload_fileupload, @upload_reference_opts), primary_key: true
    end

    create table(:post_uploads, primary_key: false) do
      add :post_id, references(:posts, @reference_opts), primary_key: true
      add :upload_key, references(:upload_fileupload, @upload_reference_opts), primary_key: true
    end

    create table(:comment_uploads, primary_key: false) do
      add :comment_id, references(:posts_comments, @reference_opts), primary_key: true
      add :upload_key, references(:upload_fileupload, @upload_reference_opts), primary_key: true
    end
  end
end
