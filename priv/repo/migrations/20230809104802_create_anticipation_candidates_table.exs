defmodule Repo.Migrations.CreateAnticipationCandidatesTable do
  use Ecto.Migration

  def change do
    create(table(:anticipaton_candidates)) do
      add :user_id, references(:accounts_userprofile, on_delete: :delete_all)
      add :topic, :string, null: false
      add :expire_at, :timestamp, null: false
      add :rewarded, :boolean, default: false

      timestamps(updated_at: false)
    end

    create(index(:anticipaton_candidates, [:user_id], unique: true))
  end
end
