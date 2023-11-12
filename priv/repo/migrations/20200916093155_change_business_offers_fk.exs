defmodule Repo.Migrations.ChangeBusinessOffersFk do
  use Ecto.Migration

  def up do
    drop_if_exists constraint(:business_offers, :business_offers_post_id_fkey)
    alter table(:business_offers) do
      modify :post_id, references(:posts, on_delete: :delete_all)
    end
  end

  def down do
    drop_if_exists constraint(:business_offers, :business_offers_post_id_fkey)
    alter table(:business_offers) do
      modify :post_id, references(:posts)
    end
  end
end
