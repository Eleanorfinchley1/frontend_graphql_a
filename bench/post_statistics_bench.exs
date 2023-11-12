# setup the database first: `MIX_ENV=bench mix ecto.setup`
# then create fake posts: `MIX_ENV=bench mix run create_posts_with_votes_and_comments.exs`
# then run the benckmark: `MIX_ENV=bench mix run bench/some_bench.exs`

alias BillBored.{Posts, Post}

# -- chooses some random post ids --
how_many_posts_to_choose = 40
import Ecto.Query

post_ids =
  Post
  |> order_by([p], desc: fragment("RANDOM()"))
  |> limit(^how_many_posts_to_choose)
  |> select([p], p.id)
  |> Repo.all()

# -- runs the benchmark --
Benchee.run(
  %{
    "single query" => fn -> Posts.get_statistics(post_ids) end,
    "multi query" => fn -> Posts.get_statistics_multi(post_ids) end
  },
  time: 10,
  warmup: 5
)
