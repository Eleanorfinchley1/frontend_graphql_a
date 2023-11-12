defmodule Repo.Migrations.MakeLivestremasRecordable do
  use Ecto.Migration

  def change do
    alter table(:livestreams) do
      add(:recorded?, :boolean, default: false, null: false)
    end

    create(index(:livestreams, [:recorded?]))
  end
end
