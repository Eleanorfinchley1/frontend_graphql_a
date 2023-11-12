defmodule Repo.Migrations.PollTableCreate do
  use Ecto.Migration

  def change do
    create_if_not_exists table("poll") do
      add :question, :text, null: false
      add :post_id, references(:pst_post)

      timestamps()
    end
  end
end
