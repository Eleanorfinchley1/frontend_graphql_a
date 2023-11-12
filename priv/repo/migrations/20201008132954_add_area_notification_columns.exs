defmodule Repo.Migrations.AddAreaNotificationColumns do
  use Ecto.Migration

  def change do
    alter(table(:area_notifications)) do
      add :linked_post_id, references(:posts), on_delete: :nilify_all
      add :categories, {:array, :string}
      add :sex, :string, length: 2
      add :min_age, :smallint
      add :max_age, :smallint
    end
  end
end
