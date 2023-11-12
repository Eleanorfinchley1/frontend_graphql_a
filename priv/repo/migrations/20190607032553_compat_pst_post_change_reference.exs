defmodule Repo.Migrations.CompatPstPostChangeReference do
  use Ecto.Migration

  def change do
    alter table(:pst_post) do
      modify :place_id, references(:places)
    end
  end
end
