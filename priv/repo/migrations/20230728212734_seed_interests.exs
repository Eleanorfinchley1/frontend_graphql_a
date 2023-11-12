defmodule Repo.Migrations.SeedInterests do
  use Ecto.Migration
  import Ecto.Query
  alias BillBored.Interest

  def change do
    Enum.each([:mix], &Application.ensure_all_started/1)
    if Mix.env() != :test do
      seed_interests()
    end
  end

  defp seed_interests() do
    json_file = "#{__DIR__}/../seeds/new_interests.json"

    with {:ok, body} <- File.read(json_file),
      {:ok, json} <- Jason.decode(body, keys: :atoms) do
      Repo.update_all(
        from(i in Interest,
          update: [set: [disabled?: true]]
        ),
        []
      )
      Enum.each(json, fn chunk ->
        params = Map.put(chunk, :inserted_at, DateTime.utc_now())
        params = Map.put(params, :disabled?, false)

        {num_row, _} = Repo.update_all(
          from(i in Interest,
            where: i.hashtag == ^params.hashtag,
            update: [set: [disabled?: ^params.disabled?, icon: ^params.icon]]
          ),
          []
        )

        if num_row == 0 do
          Repo.insert_all(
            Interest,
            [params],
            returning: true,
            on_conflict: {:replace, [:hashtag, :disabled?, :icon]},
            conflict_target: [:id]
          )
        end
      end)

    else
      err -> IO.inspect(err)
    end
  end
end
