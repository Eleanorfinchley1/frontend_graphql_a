defmodule Repo.Migrations.CreateUserRecommendations do
  use Ecto.Migration

  def up do
    create(table(:user_recommendations)) do
      add :user_id, references(:accounts_userprofile)
      add :type, :string
      add :inserted_at, :timestamptz
      add :updated_at, :timestamptz
    end

    create(index(:user_recommendations, [:type]))
    create(index(:user_recommendations, [:user_id, :type], unique: true))

    alter(table(:accounts_userprofile)) do
      add :flags, :jsonb
    end

    execute("UPDATE accounts_userprofile SET flags = json_build_object('autofollow', 'done')")
  end

  def down do
    alter(table(:accounts_userprofile)) do
      remove :flags
    end

    drop(table(:user_recommendations))
  end
end
