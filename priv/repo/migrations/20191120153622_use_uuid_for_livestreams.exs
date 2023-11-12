defmodule Repo.Migrations.UseUuidForLivestreams do
  use Ecto.Migration

  def up do
    drop table(:livestream_comment_votes)
    drop table(:livestream_votes)
    drop table(:livestream_comments)
    drop table(:livestream_views)
    drop table(:livestreams)

    create table(:livestreams, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
      add :owner_id, references(:accounts_userprofile, on_delete: :delete_all), null: false
      add :ended_at, :utc_datetime_usec
      add :active?, :boolean, default: false, null: false
      add :recorded?, :boolean, default: false, null: false

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    # TODO can be done in the create macro above?
    # TODO location cannot be null
    execute("SELECT AddGeometryColumn ('livestreams', 'location', 4326, 'POINT', 2);")

    create index(:livestreams, [:owner_id])
    create index(:livestreams, [:location], using: "gist")
    create index(:livestreams, [:recorded?])

    create table(:livestream_comments) do
      add :body, :text, null: false
      add :author_id, references(:accounts_userprofile, on_delete: :delete_all), null: false

      add :livestream_id, references(:livestreams, on_delete: :delete_all, type: :uuid),
        null: false

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create index(:livestream_comments, [:livestream_id, :author_id])

    create table(:livestream_votes, primary_key: false) do
      add :livestream_id, references(:livestreams, on_delete: :delete_all, type: :uuid),
        primary_key: true

      add :user_id, references(:accounts_userprofile, on_delete: :delete_all), primary_key: true
      add :vote_type, :string, null: false

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create table(:livestream_comment_votes, primary_key: false) do
      add :comment_id, references(:livestream_comments, on_delete: :delete_all), primary_key: true
      add :user_id, references(:accounts_userprofile, on_delete: :delete_all), primary_key: true
      add :vote_type, :string, null: false

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    create table(:livestream_views, primary_key: false) do
      add :livestream_id, references(:livestreams, on_delete: :delete_all, type: :uuid),
        primary_key: true

      add :user_id, references(:accounts_userprofile, on_delete: :delete_all), primary_key: true

      timestamps(inserted_at: :created, updated_at: :updated)
    end
  end

  def down do
    raise "not implemented"
  end
end
