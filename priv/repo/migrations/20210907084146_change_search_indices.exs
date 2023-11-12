defmodule Repo.Migrations.ChangeSearchIndices do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute("DROP INDEX IF EXISTS accounts_userprofile_username_8e8bc851_like");

    execute("DROP INDEX IF EXISTS accounts_userprofile_username_trgm_index");
    execute("CREATE INDEX CONCURRENTLY accounts_userprofile_username_trgm_index ON accounts_userprofile USING gist (username gist_trgm_ops)");
  end

  def down do
    execute("DROP INDEX IF EXISTS accounts_userprofile_username_trgm_index");
    execute("CREATE INDEX CONCURRENTLY accounts_userprofile_username_trgm_index ON accounts_userprofile USING gin (username gin_trgm_ops)");

    execute("CREATE INDEX CONCURRENTLY accounts_userprofile_username_8e8bc851_like ON accounts_userprofile USING btree (username varchar_pattern_ops)");
  end
end
