defmodule Repo.Migrations.UseGeographies do
  use Ecto.Migration

  def change do
    [
      %{table: "posts", column: "location"},
      %{table: "posts", column: "fake_location"},
      %{table: "eventbrite_requests", column: "location"},
      %{table: "eventful_requests", column: "location"},
      %{table: "events", column: "location"},
      %{table: "livestreams", column: "location"},
      %{table: "places", column: "location"}
    ]
    |> Enum.each(fn %{table: table, column: column} ->
      execute "ALTER TABLE #{table} ALTER COLUMN #{column} TYPE geography(Point, 4326);",
              "ALTER TABLE #{table} ALTER COLUMN #{column} TYPE geometry(Point, 4326);"
    end)
  end
end
