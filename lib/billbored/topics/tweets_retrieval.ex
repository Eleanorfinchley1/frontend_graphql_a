defmodule BillBored.Topics.TweetsRetrieval do
  @moduledoc """
  Retrieve last 100 Tweets for `Concordia`, `mcgillu` using tesla.
  """
  use Tesla

  @bearer System.get_env("TWITTER_BEARER_TOKEN")

  plug(Tesla.Middleware.BaseUrl, "https://api.twitter.com/")
  plug(Tesla.Middleware.Headers, [{"Authorization", "Bearer #{@bearer}"}])
  plug(Tesla.Middleware.JSON)
  # between 5 and 100 in twitter api
  @max_results 100
  # @usernames ["Concordia", "mcgillu"]
  @ids ["18173399", "18065266"]
  def university_name("18173399"), do: "concordia"
  def university_name("18065266"), do: "mcgillu"

  def run do
    Enum.map(@ids, fn id ->
      case get_tweets(id) do
        {:ok, tweets} ->
          {university_name(id), tweets}

        {:error, _reason} ->
          {university_name(id), []}
      end
    end)
  end

  @doc "use just for getting ids from iex or similar method"
  def lookup_user(usernames) when is_list(usernames) do
    case get("/2/users/by", query: [usernames: Enum.join(usernames, ",")]) do
      {:ok, %Tesla.Env{body: %{"data" => data}}} -> data
      {:error, reason} -> reason
    end
  end

  defp get_tweets(id) do
    with {:ok, %Tesla.Env{body: %{"data" => data}}} <- user_tweets(id),
         tweets <- Enum.map(data, fn %{"text" => text} -> text end),
         cleaned_data <-
           Enum.map(tweets, fn tweet ->
             clean(tweet)
           end) do
      {:ok, cleaned_data}
    else
      {:ok, %Tesla.Env{body: %{"errors" => errors}}} -> {:error, errors}
      {:ok, %Tesla.Env{body: %{"detail" => errors}}} -> {:error, errors}
    end
  end

  defp user_tweets(id) do
    get("/2/users/#{id}/tweets", query: [max_results: @max_results])
  end

  # cleanup string from url mention hashtags and whitespace
  defp clean(tweet) do
    tweet
    |> String.replace(~r"(http[s]?\://\S+)|([\[\(].*[\)\]])|([#@]\S+)|\n", "")
    |> String.replace(~r"\s+", " ")
    |> String.trim()
  end
end
