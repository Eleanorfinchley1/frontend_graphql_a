
alias BillBored.{Post, User}
alias BillBored.Geo.Point
alias BillBored.Clickhouse

new_york = %{"lon" => "-73.935242", "lat" => "40.730610", "country" => "USA", "city" => "New York"}
moscow = %{"lon" => "37.61556", "lat" => "55.75222", "country" => "Russia", "city" => "Moscow"}
london = %{"lon" => "-0.1257", "lat" => "51.5085", "country" => "Great Britain", "city" => "London"}

insert_post = fn post, user, params ->
  {:ok, post_view} = Clickhouse.PostView.build(post, user, params)
  Clickhouse.PostViews.create(post_view)
end

insert_post.(%Post{id: 1, business_id: 10}, %User{id: 1, sex: "M"}, new_york)
insert_post.(%Post{id: 1, business_id: 10}, %User{id: 2, sex: "F", birthdate: ~D[1999-01-01]}, moscow)
insert_post.(%Post{id: 2}, %User{id: 3}, london)

moscow_locations_1 = [
  {55.74765396061102, 37.58735152455694},
  {55.74775406736308, 37.58772042496377},
  {55.74782610110155, 37.58799804274332},
  {55.74800724905921, 37.58787758823732},
  {55.74815608574438, 37.58777783369638},
  {55.74831074925268, 37.58767525817807}
]

moscow_locations_2 = [
  {55.74913733789173, 37.58557326530778},
  {55.74933831634012, 37.58623388696961},
  {55.749137335469875, 37.58692723996768}
]

moscow_locations_3 = [
  {55.74616277912423, 37.58030612487175},
  {55.74600608069638, 37.5798918724264},
  {55.746471160244894, 37.57968696789121}
]

insert_user_location = fn user, point, attrs ->
  {:ok, user_location} = Clickhouse.UserLocation.build(user, point, attrs)
  Clickhouse.UserLocations.create(user_location)
end

visited_at = Timex.shift(DateTime.utc_now(), days: -1)

moscow_locations_1 |> Enum.with_index() |> Enum.each(fn {{lat, lon}, idx} ->
  insert_user_location.(%User{id: 1}, %Point{long: lon, lat: lat}, %{"visited_at" => Timex.shift(visited_at, minutes: 10 * idx)})
end)

moscow_locations_2 |> Enum.with_index() |> Enum.each(fn {{lat, lon}, idx} ->
  insert_user_location.(%User{id: 1}, %Point{long: lon, lat: lat}, %{"visited_at" => Timex.shift(visited_at, minutes: 10 * idx)})
end)

moscow_locations_3 |> Enum.with_index() |> Enum.each(fn {{lat, lon}, idx} ->
  insert_user_location.(%User{id: 1}, %Point{long: lon, lat: lat}, %{"visited_at" => Timex.shift(visited_at, minutes: 10 * idx)})
end)
