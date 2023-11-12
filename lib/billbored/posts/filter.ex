defmodule BillBored.Posts.Filter do
  def parse(filter_params, initial \\ %{}) do
    filter =
      filter_params
      |> Enum.reduce(initial, fn {key, value}, acc ->
        case key do
          "show_" <> kind when kind in ["paid", "free", "child_friendly", "courses"] ->
            Map.put(acc, String.to_atom(key), parse_bool(value))

          "dates" ->
            Map.put(
              acc,
              :dates,
              value
              |> Enum.map(fn date ->
                {:ok, date, _} = DateTime.from_iso8601(date)
                date
              end)
              |> case do
                [] -> nil
                [_] = date -> date
                [_, _] = daterange -> daterange
                [first | rest] -> [first, List.last(rest)]
              end
            )

          "categories" ->
            Map.put(acc, :categories, value)

          "keyword" ->
            if is_binary(value) and String.trim(value) == "" do
              Map.put(acc, :keyword, nil)
            else
              Map.put(acc, :keyword, value)
            end
        end
      end)
      |> Enum.reject(fn
        {_k, []} -> true
        {_k, v} -> is_nil(v)
      end)
      |> Map.new()

    {:ok, filter}
  end

  defp parse_bool(true), do: true
  defp parse_bool("true"), do: true
  defp parse_bool(_), do: false
end
