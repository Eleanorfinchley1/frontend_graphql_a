defmodule BillBored.Topics.Generator do
  @moduledoc """
  Generate topics by using openai text-davinci-003 model.

  it expect data to be in this shape of array has two elements,
  every element is a tuple has university name and second is last 100 tweets.
  """
  def run(data) do
    prepare_data(data)
  end

  defp prepare_data(data) do
    data
    |> process_data()
    |> clean_data()
  end

  def process_data([concordia, mcgillu]), do: [process_data(concordia), process_data(mcgillu)]

  def process_data([tweets | []]), do: process_data(tweets)

  def process_data({name, tweets} = data) do

    with {:ok, result} <-
           OpenAI.completions(
             "text-davinci-003",
             prompt: """
             Extract ten just ten topics young adults between the ages of 18 and 23 could chat about it from tweets.
             Topic should be fun, less educational, trendy for young poeple.
             Tweets:
                 #{tweets}
             Ten topics extracted from tweets:
            """,
             max_tokens: 120,
             temperature: 1
           ),
         %{choices: [%{"text" => text} | _]} <- result do
      %{university_name: name, topics: text}
    else
      _ ->
        process_data(data)
    end
  end

  defp clean_data(data) do
    data
    |> Enum.map(fn %{topics: topics} = data ->
      topics =
        topics
        |> String.split("\n")
        |> Enum.reject(&(&1 === ""))
        |> Enum.map(fn topic ->
          topic
          |> String.replace(~r/^[0-9]*\./, "")
          |> String.trim()
        end)

      %{data | topics: topics}
    end)
  end
end
