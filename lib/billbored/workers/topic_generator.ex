defmodule BillBored.Workers.TopicGenerator do
  alias BillBored.Topics
  alias BillBored.Topics.Generator
  alias BillBored.Topics.TweetsRetrieval

  def call() do
    tweets = TweetsRetrieval.run()
    meta = Generator.run(tweets)
    {:ok, _topic} = Topics.create_topic(meta)
  end
end
