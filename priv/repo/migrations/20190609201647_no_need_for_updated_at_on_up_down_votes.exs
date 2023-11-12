defmodule Repo.Migrations.NoNeedForUpdatedAtOnUpDownVotes do
  use Ecto.Migration

  def change do
    alter table(:posts_upvotes) do
      remove :inserted_at
      remove :updated_at

      timestamps updated_at: false
    end

    alter table(:posts_downvotes) do
      remove :inserted_at
      remove :updated_at

      timestamps updated_at: false
    end
  end
end
