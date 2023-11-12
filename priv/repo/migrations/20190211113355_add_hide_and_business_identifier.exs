defmodule Repo.Migrations.AddHideAndBusinessIdentifier do
  use Ecto.Migration

  def change do
    alter table(:pst_post) do
      add(:is_hide, :boolean, default: false, null: false)
      add(:is_business, :boolean, default: false, null: false)
      add(:business_account_id, :integer, default: nil, null: true)
    end
  end

  def down do
    alter table(:pst_post) do
      remove(:is_hide)
      remove(:is_business)
      remove(:business_account_id)
    end
  end
end
