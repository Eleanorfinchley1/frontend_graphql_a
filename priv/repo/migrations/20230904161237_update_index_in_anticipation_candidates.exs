defmodule Repo.Migrations.UpdateIndexInAnticipationCandidates do
  use Ecto.Migration

  def change do
    # remove unique constraint
    drop(index(:anticipaton_candidates, [:user_id], unique: true))
    create(index(:anticipaton_candidates, [:user_id]))
  end
end
