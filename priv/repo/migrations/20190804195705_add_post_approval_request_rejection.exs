defmodule Repo.Migrations.AddPostApprovalRequestRejection do
  use Ecto.Migration

  def change do
    create table(:post_approval_request_rejection, primary_key: false) do
      add(:post_id, references(:posts, on_delete: :delete_all), primary_key: true)

      add(:approver_id, references(:accounts_userprofile, on_delete: :delete_all),
        primary_key: true
      )

      add(:requester_id, references(:accounts_userprofile, on_delete: :delete_all),
        primary_key: true
      )

      add(:note, :text)

      timestamps()
    end
  end
end
