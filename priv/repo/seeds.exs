
import Ecto.Query

alias BillBored.User
alias BillBored.Post
alias BillBored.Event
alias BillBored.Interest
alias BillBored.Chat.Room
alias BillBored.Chat.Room.DropchatStream

empty_user_attributes = %{
  avatar: "",
  avatar_thumbnail: "",
  password: "",
  is_superuser: false,
  first_name: "",
  last_name: "",
  email: "",
  is_staff: false,
  is_active: false,
  bio: "",
  sex: "",
  prefered_radius: 0,
  country_code: "",
  enable_push_notifications: false,
  area: "",
  flags: %{"access" => "granted"}
}

make_user = fn attrs ->
  if user = Repo.one(from(u in User, where: u.username == ^attrs[:username], limit: 1)) do
    user
  else
    Ecto.Changeset.change(%User{}, Map.merge(empty_user_attributes, attrs))
    |> Repo.insert!()
  end
end

%{id: author_id} = author = make_user.(%{password: "123456", email: "a@b.com", username: "admin", phone: "123", verified_phone: "123"})
%{id: user_id} = user = make_user.(%{password: "123456", email: "user@example.com", username: "user", phone: "234", verified_phone: "234"})

Ecto.Changeset.change(
  %BillBored.User.AuthToken{},
  %{
    user_id: user_id, key: "SFMyNTY.g3QAAAACZAAEZGF0YWIAP5keZAAGc2lnbmVkbgYA2e6OfHMB.H7ePwzhlSVgpcEcUpaEYUqiHeVA2NGUzqHLF739KCVg"
  }
)
|> Repo.insert!(on_conflict: {:replace, [:key]}, conflict_target: :user_id)

make_user.(%{password: "123456", email: "business@example.com", username: "business", is_business: true})

insert_post = fn attrs ->
  common = Map.take(attrs, [:title, :location])
  post =
    Post.changeset(%Post{}, attrs)
    |> Repo.insert!()

  d1 = Timex.shift(DateTime.utc_now(), days: 1)
  d2 = Timex.shift(DateTime.utc_now(), days: 2)
  Map.merge(%Event{post_id: post.id, date: d1, other_date: d2}, common) |> Repo.insert!()

  post
end

posts = if Repo.one(from(p in Post, select: count(p))) > 0 do
  Repo.all(from(p in Post))
else
  {:ok, posts} = Repo.transaction(fn _ ->
    p1 = insert_post.(%{author_id: author_id, title: "Post 1", body: "", type: "event", location: %BillBored.Geo.Point{lat: 51.23399, long: -12.138531}})
    p2 = insert_post.(%{author_id: author_id, title: "Post 2", body: "", type: "event", location: %BillBored.Geo.Point{lat: 51.172073, long: -12.164037}})
    p3 = insert_post.(%{author_id: author_id, title: "Post 3", body: "", type: "event", location: %BillBored.Geo.Point{lat: 51.188059, long: -12.139366}})
    # _p4 = insert_post.(%{author_id: author_id, title: "Post 4", type: "event", location: %BillBored.Geo.Point{lat: 51.117661, long: -12.161299}})
    # _p5 = insert_post.(%{author_id: author_id, title: "Post 5", type: "event", location: %BillBored.Geo.Point{lat: 51.110635, long: -12.147783}})
    p4 = insert_post.(%{author_id: author_id, title: "Post 4", body: "", type: "event", location: %BillBored.Geo.Point{lat: 51.10899, long: -12.14659}})
    p5 = insert_post.(%{author_id: author_id, title: "Post 5", body: "", type: "event", location: %BillBored.Geo.Point{lat: 51.10803, long: -12.14646}})

    [p1, p2, p3, p4, p5]
  end)

  posts
end

interests =
  ~w(algeria belgium belarus bicycling billiards climbing cryptography electronics mahjong skateboarding singing)
  |> Enum.map(&(%{hashtag: &1, inserted_at: DateTime.utc_now()}))

Repo.insert_all(Interest, interests, conflict_target: [:hashtag], on_conflict: :nothing)

# location = %BillBored.Geo.Point{lat: 51.13606981407861, long: -12.17065179253916085}
# radius = 8000

location = %BillBored.Geo.Point{lat: 51.156266683793206, long: -12.158332626159194}
radius = 11069.935546875

# markers = BillBored.Posts.list_markers({location, radius}, [])

# [
#   {%BillBored.Geo.Point{lat: 51.180066, long: -12.151701500000001}, 3030},
#   {%BillBored.Geo.Point{lat: 51.108509999999995, long: -12.146525}, 3034},
#   {location, radius},
#   BillBored.Geo.Hash.all_within(location, radius, 5),
#   Enum.map(posts, & &1.location)
# ]
# |> BillBored.Geo.Json.build()
# |> Jason.encode!()
# |> IO.puts()

insert_chat_room = fn attrs, stream_attrs ->
  location = %BillBored.Geo.Point{lat: 51.156266683793206, long: -12.158332626159194}

  attrs =
    Map.take(attrs, [:private, :title, :chat_type])
    |> Map.merge(%{
      location: location,
      safe_location: location,
      color: "#AAAAAA",
      reach_area_radius: 15,
      last_interaction: Timex.now()
    })

  chat_room = Repo.insert!(Room.changeset(%Room{}, attrs))

  stream = if stream_attrs do
    stream_attrs =
      Map.take(stream_attrs, [:admin, :title, :status])
      |> Map.merge(%{dropchat: chat_room})

    Repo.insert!(DropchatStream.create_changeset(%DropchatStream{}, stream_attrs))
  else
    nil
  end

  {chat_room, stream}
end

insert_chat_room.(%{private: false, title: "Room 1", chat_type: "dropchat"}, %{title: "Stream 1", status: "active", admin: author})
