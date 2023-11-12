alias BillBored.Search

# test run to see that resources are not empty
count = length(Search.search_all("test").users)

IO.puts("-- benchmarking a query that returns #{count} elements\n\n")

# -- runs the benchmark --
Benchee.run(
  %{
    "multi query" => fn -> Search.search_all("test") end
  },
  time: 10,
  warmup: 5
)
