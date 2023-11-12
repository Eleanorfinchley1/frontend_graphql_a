# alias BillBored.Posts

# lat = :rand.uniform(100) - 50
# lon = :rand.uniform(100) - 50
# geometry = %Geo.Point{coordinates: {lat, lon}, srid: 4326}

# # test run to see that posts are not empty
# l1 = length(Posts.list_by_location(geometry))
# l2 = length(Posts.list_by_location(geometry))

# unless l1 == l2 do
#   raise("length of the two queries are not equal, geometry: #{inspect(geometry)}")
# end

# IO.puts("-- benchmarking a query that returns #{l2} elements\n\n")

# # -- runs the benchmark --
# Benchee.run(
#   %{
#     "single query" => fn -> Posts.list_by_location(geometry) end,
#     "multi query" => fn -> Posts.list_by_location_multi(geometry) end
#   },
#   time: 10,
#   warmup: 5
# )
