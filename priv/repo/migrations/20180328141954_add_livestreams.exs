defmodule Repo.Migrations.AddLivestreams do
  use Ecto.Migration

  def up do
    create table(:livestreams) do
      add(:title, :string, null: false)
      # TODO delete_all or not
      add(:owner_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:ended_at, :utc_datetime_usec)
      add(:active?, :boolean, default: false, null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end

    # TODO can be done in the create macro above?
    execute("SELECT AddGeometryColumn ('livestreams', 'location', 4326, 'POINT', 2);")

    # TODO location cannot be null

    create(index(:livestreams, [:owner_id]))
    create(index(:livestreams, [:location], using: "gist"))

    # create(index(:livestreams, [:id], where: "'active?'", name: :livestreams_active_index))

    create table(:livestream_comments) do
      add(:body, :text, null: false)

      # TODO delete_all or not
      add(:author_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:livestream_id, references(:livestreams, on_delete: :delete_all), null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end
  end

  def down do
    drop(table(:livestream_comments))
    drop(table(:livestreams))
  end
end
