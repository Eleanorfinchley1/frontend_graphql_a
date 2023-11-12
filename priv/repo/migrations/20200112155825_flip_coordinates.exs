defmodule Repo.Migrations.FlipCoordinates do
  use Ecto.Migration
  # TODO remove after running
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
      update = "UPDATE #{table} SET #{column}=ST_FlipCoordinates(#{column});"
      execute update, update
    end)
  end
end
