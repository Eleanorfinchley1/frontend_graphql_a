defmodule Repo.Migrations.AddPostReportReasons do
  use Ecto.Migration

  def change do
    create table(:post_report_reasons) do
      add(:reason, :string, size: 255, null: false)

      timestamps()
    end

    create index(:post_report_reasons, :reason, unique: true)
  end
end
