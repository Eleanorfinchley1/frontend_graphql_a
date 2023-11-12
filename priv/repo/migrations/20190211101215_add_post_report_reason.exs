defmodule Repo.Migrations.AddTableForPostReportReason do
  use Ecto.Migration

  def change do
    create table(:pst_post_report_reason) do
      add(:report_reason, :string, null: false)

      timestamps(inserted_at: :created, updated_at: :updated)
    end
  end
end
