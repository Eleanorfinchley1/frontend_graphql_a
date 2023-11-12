defmodule Repo.Migrations.AddPostApproved do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add(:approved?, :boolean, default: true)
    end
  end
end
