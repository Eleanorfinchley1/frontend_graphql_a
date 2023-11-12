defmodule Repo.Migrations.CompatDropContraintsPstPost do
  use Ecto.Migration

  def change do
    drop constraint(:pst_post, "pst_post_place_id_cc2ba08c_fk_places_place_id")
  end
end
