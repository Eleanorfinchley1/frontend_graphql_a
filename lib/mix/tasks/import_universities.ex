defmodule Mix.Tasks.ImportUniversities do

  @allowed_universities ["McGill University", "Concordia University"]
  @start_apps [:httpoison]

  use Mix.Task

  require Logger

  @impl Mix.Task
  def run(_args) do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    # Mix.Task.run("app.start")

    case HTTPoison.get!("http://universities.hipolabs.com/search?") do
      response  ->
        process_response(response)
    end
  end

  defp process_response(response) do
    universities =
      response.body
      |> Jason.decode!()
      |> Enum.map(fn university ->
        university
        |> Map.take(["name", "country"])
        |> Map.put("allowed", is_allowed?(university))
      end)

    Ecto.Migrator.with_repo(Repo, fn _repo ->
      Enum.each(universities, &BillBored.Universities.create/1)
    end)
  end

  defp is_allowed?(university), do: university["name"] in @allowed_universities
end
