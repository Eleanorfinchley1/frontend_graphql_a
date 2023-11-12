defmodule Repo.Migrations.AddTableForPostReport do
  use Ecto.Migration

  def change do
    create table(:pst_post_report) do
      add(:post_id, references(:pst_post), null: false)
      add(:reporter_id, references(:accounts_userprofile), null: false)
      add(:reason_id, references(:pst_post_report_reason), null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end
  end
end
