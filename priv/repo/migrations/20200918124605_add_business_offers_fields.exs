defmodule Repo.Migrations.AddBusinessOffersFields do
  use Ecto.Migration

  def change do
    alter table(:business_offers) do
      add :discount, :string
      add :qr_code, :text
      add :bar_code, :string
    end
  end
end
