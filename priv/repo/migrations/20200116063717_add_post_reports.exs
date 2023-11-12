defmodule Repo.Migrations.AddPostReports do
  use Ecto.Migration

  def change do
    create table(:post_reports) do
      add(:post_id, references(:posts, on_delete: :delete_all), null: false)
      add(:reporter_id, references(:accounts_userprofile, on_delete: :delete_all), null: false)
      add(:reason_id, references(:post_report_reasons), null: false)

      timestamps()
    end

    create index(:post_reports, [:post_id, :reporter_id, :reason_id], unique: true)
  end
end
