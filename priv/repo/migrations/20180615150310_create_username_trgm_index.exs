defmodule Repo.Migrations.CreateUsernameTrgmIndex do
  use Ecto.Migration

  def up do
    execute(
      "create index accounts_userprofile_username_trgm_index on accounts_userprofile using gin (username gin_trgm_ops);"
    )
  end

  def down do
    execute("drop index accounts_userprofile_username_trgm_index;")
  end
end
