defmodule Repo.Migrations.AddAvatarAndIconInUniversity do
  use Ecto.Migration

  def change do
    alter table "university" do
      add :avatar, :string, null: false
      add :avatar_thumbnail, :string, null: false
      add :icon, :string
    end
  end
end
