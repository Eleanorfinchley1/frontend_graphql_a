defmodule Repo.Migrations.AddAccessRestrictionPolicyKvEntry do
  use Ecto.Migration

  def up do
    execute("INSERT INTO kv_entries (key, value, updated_at) VALUES ('access_restriction_policy', '{\"enabled\": true}'::jsonb, NOW())")
  end

  def down do
    execute("DELETE FROM kv_entries WHERE key = 'access_restriction_policy'");
  end
end
