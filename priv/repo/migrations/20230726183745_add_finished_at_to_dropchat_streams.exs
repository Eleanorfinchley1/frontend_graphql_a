defmodule :"Elixir.Repo.Migrations.AddFinishedAtToDropchatStreams" do
  use Ecto.Migration

  def change do
    alter table "dropchat_streams" do
      add :finished_at, :timestamp
    end
  end
end
