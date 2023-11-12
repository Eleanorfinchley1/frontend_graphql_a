defmodule FakePosts do
  @moduledoc "To be used to create fake data for benchmarking"

  alias BillBored.{Post, PostReportReason, PostReport, User, User.Block}

  @spec random_location :: Geo.Point.t()
  defp random_location do
    lat = :rand.uniform(100) - 50
    lon = :rand.uniform(100) - 50
    %BillBored.Geo.Point{lat: lat, long: lon}
  end

  @spec insert_users(pos_integer) :: [user_ids :: pos_integer]
  def insert_users(count) do
    1..count
    |> Enum.map(fn _ ->
      image_url = Faker.Avatar.image_url()

      %{
        password: Faker.String.base64(10),
        is_superuser: false,
        username: Faker.String.base64(10),
        first_name: Faker.Name.first_name(),
        last_name: Faker.Name.last_name(),
        email: Faker.Internet.email(),
        is_staff: false,
        is_active: true,
        date_joined: DateTime.utc_now(),
        avatar: image_url,
        bio: Faker.Lorem.sentence(10),
        sex: "m",
        birthdate: Faker.Date.date_of_birth(),
        prefered_radius: 1,
        enable_push_notifications: false,
        avatar_thumbnail: image_url,
        country_code: Faker.Address.country_code(),
        phone: Faker.Phone.EnUs.phone(),
        area: Faker.Address.city()
      }
    end)
    |> Enum.chunk_every(1000)
    |> Enum.reduce([], fn chunk, acc_user_ids ->
      {_inserted_count, users} = Repo.insert_all(User, chunk, returning: [:id])
      Enum.map(users, fn %User{id: user_id} -> user_id end) ++ acc_user_ids
    end)
  end

  @spec insert_posts(pos_integer, [pos_integer]) :: [post_ids :: pos_integer]
  def insert_posts(count, author_ids) do
    1..count
    |> Enum.map(fn _ ->
      %{
        title: Faker.Lorem.sentence(1),
        body: Faker.Lorem.sentence(15),
        location: random_location(),
        private?: false,
        type: "regular",
        author_id: Enum.random(author_ids),
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
    end)
    |> Enum.chunk_every(1000)
    |> Enum.reduce([], fn chunk, acc_post_ids ->
      {_count, posts} = Repo.insert_all(Post, chunk, returning: [:id])
      Enum.map(posts, fn %Post{id: post_id} -> post_id end) ++ acc_post_ids
    end)
  end

  @spec insert_upvotes(pos_integer, [pos_integer], [pos_integer]) :: :ok
  def insert_upvotes(count, post_ids, user_ids) do
    1..count
    |> Enum.map(fn _ ->
      %{
        post_id: Enum.random(post_ids),
        user_id: Enum.random(user_ids),
        inserted_at: DateTime.utc_now()
      }
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Repo.insert_all(Post.Upvote, chunk, on_conflict: :nothing)
    end)
  end

  @spec insert_downvotes(pos_integer, [pos_integer], [pos_integer]) :: :ok
  def insert_downvotes(count, post_ids, user_ids) do
    1..count
    |> Enum.map(fn _ ->
      %{
        post_id: Enum.random(post_ids),
        user_id: Enum.random(user_ids),
        inserted_at: DateTime.utc_now()
      }
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Repo.insert_all(Post.Downvote, chunk, on_conflict: :nothing)
    end)
  end

  @spec insert_comments(pos_integer, [pos_integer], [pos_integer]) :: :ok
  def insert_comments(count, post_ids, user_ids) do
    1..count
    |> Enum.map(fn _ ->
      %{
        body: Faker.Lorem.sentence(1),
        post_id: Enum.random(post_ids),
        author_id: Enum.random(user_ids),
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Repo.insert_all(Post.Comment, chunk, on_conflict: :nothing)
    end)
  end

  def insert_post_reports(count, post_ids, user_ids) do
    reasons =
      [
        "This is a spam",
        "This is a scam",
        "This is Inappropriate or Adult content",
        "I think topic or language is offensive"
      ]
      |> Enum.map(fn reason ->
        %{
          reason: reason,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      end)

    {_, reasons} =
      Repo.insert_all(PostReportReason, reasons, on_conflict: :nothing, returning: [:id])

    reason_ids = reasons |> Enum.map(& &1.id)

    post_ids = post_ids |> Enum.take_random(div(Enum.count(post_ids), 10))

    1..count
    |> Enum.map(fn _ ->
      %{
        post_id: Enum.random(post_ids),
        reporter_id: Enum.random(user_ids),
        reason_id: Enum.random(reason_ids),
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Repo.insert_all(PostReport, chunk, on_conflict: :nothing)
    end)
  end

  def insert_user_blocks(count, user_ids) do
    1..count
    |> Enum.flat_map(fn _ ->
      user1_id = Enum.random(user_ids)
      user2_id = Enum.random(user_ids)

      if user1_id != user2_id do
        [
          %{
            to_userprofile_id: user1_id,
            from_userprofile_id: user2_id
          }
        ]
      else
        []
      end
    end)
    |> Enum.chunk_every(1000)
    |> Enum.each(fn chunk ->
      Repo.insert_all(Block, chunk, on_conflict: :nothing)
    end)
  end

  def setup(opts \\ %{}) do
    opts =
      Map.merge(
        %{
          users_count: 1000,
          posts_count: 50000,
          post_upvotes_count: 50000,
          post_downvotes_count: 50000,
          post_comments_count: 50000,
          post_reports_count: 1000,
          user_blocks_count: 200
        },
        opts
      )

    IO.puts("-- creating users")
    user_ids = FakePosts.insert_users(Map.fetch!(opts, :users_count))

    IO.puts("-- creating posts")
    post_ids = FakePosts.insert_posts(Map.fetch!(opts, :posts_count), user_ids)

    IO.puts("-- creating post upvotes")
    FakePosts.insert_upvotes(Map.fetch!(opts, :post_upvotes_count), post_ids, user_ids)

    IO.puts("-- creating post downvotes")
    FakePosts.insert_downvotes(Map.fetch!(opts, :post_downvotes_count), post_ids, user_ids)

    IO.puts("-- creating post comments")
    FakePosts.insert_comments(Map.fetch!(opts, :post_comments_count), post_ids, user_ids)

    IO.puts("-- creating post reports")
    FakePosts.insert_post_reports(Map.fetch!(opts, :post_reports_count), post_ids, user_ids)

    IO.puts("-- creating user blocks")
    FakePosts.insert_user_blocks(Map.fetch!(opts, :user_blocks_count), user_ids)
  end

  def cleanup do
    Repo.truncate(Post)
    Repo.truncate(Post.Upvote)
    Repo.truncate(Post.Downvote)
    Repo.truncate(Post.Comment)
  end
end

if System.get_env("BENCH_SMALL") do
  FakePosts.setup(%{
    posts_count: 1000,
    post_upvotes_count: 1000,
    post_downvotes_count: 1000,
    post_comments_count: 1000
  })
else
  FakePosts.setup()
end
