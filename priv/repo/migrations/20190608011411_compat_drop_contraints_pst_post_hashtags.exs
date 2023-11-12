defmodule Repo.Migrations.CompatDropContraintsPstPostHashtags do
  use Ecto.Migration

  def change do
    drop constraint(
           :pst_post_hashtags,
           "pst_post_hashtags_interest_id_d1ac07a7_fk_interests_interest_id"
         )
  end
end
