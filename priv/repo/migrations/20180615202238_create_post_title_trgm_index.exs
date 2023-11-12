defmodule Repo.Migrations.CreatePostTitleTrgmIndex do
  use Ecto.Migration

  def up do
    execute("create index pst_post_title_trgm_index on pst_post using gin (title gin_trgm_ops);")
  end

  def down do
    execute("drop index pst_post_title_trgm_index;")
  end
end
