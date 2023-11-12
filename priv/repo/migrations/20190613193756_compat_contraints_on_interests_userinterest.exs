defmodule Repo.Migrations.CompatContraintsOnInterestsUserinterest do
  use Ecto.Migration

  def change do
    drop constraint(
           :interests_userinterest,
           "interests_userintere_interest_id_9ab9062c_fk_interests"
         )

    alter table(:interests_userinterest) do
      modify :interest_id, references("interests", on_delete: :delete_all), null: false
    end
  end
end
