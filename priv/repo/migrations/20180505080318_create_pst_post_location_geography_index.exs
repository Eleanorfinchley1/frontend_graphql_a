defmodule Repo.Migrations.CreatePstPostLocationGeographyIndex do
  use Ecto.Migration

  def up do
    execute(
      "CREATE INDEX pst_post_location_id2 ON pst_post USING gist (((location)::geography));"
    )
  end

  def down do
    execute("DROP INDEX pst_post_location_id2;")
  end
end
