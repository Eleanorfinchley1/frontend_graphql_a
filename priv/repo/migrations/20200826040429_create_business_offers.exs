defmodule Repo.Migrations.CreateBusinessOffers do
  use Ecto.Migration

  def change do
    create table(:business_offers) do
      add :business_id, references(:accounts_userprofile)
      add :post_id, references(:posts)

      add :discount_code, :string
      add :business_address, :text
      add :expires_at, :utc_datetime_usec, null: false

      timestamps()
    end

    create(index(:business_offers, [:post_id]))
    create(index(:business_offers, [:expires_at]))
  end
end
