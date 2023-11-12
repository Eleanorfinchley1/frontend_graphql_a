defmodule Repo.Migrations.MakeCommentBodyText do
  use Ecto.Migration

  def change do
    alter table(:chat_message) do
      modify :message, :text, from: :string
    end
  end
end
