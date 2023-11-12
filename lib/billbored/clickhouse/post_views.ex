defmodule BillBored.Clickhouse.PostViews do
  alias BillBored.Clickhouse.PostView

  def create(%PostView{} = post_view) do
    Pillar.insert(
      BillBored.Clickhouse.conn(),
      """
        INSERT INTO post_views (
          post_id, business_id, geohash, lon, lat,
          user_id, age, sex, country, city, viewed_at
        ) VALUES (
          {post_id}, {business_id}, {geohash}, {lon}, {lat},
          {user_id}, {age}, {sex}, {country}, {city}, {viewed_at}
        )
      """,
      Map.from_struct(post_view)
    )
  end

  def all() do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      """
        SELECT
          post_id, business_id, geohash, lon, lat,
          user_id, age, sex, country, city, date, viewed_at
        FROM
          post_views
      """,
      %{}
    )
  end

  def post_views_by_sex(post_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      "SELECT sex, uniq(user_id) as unique_views FROM post_views WHERE post_id = {post_id} GROUP BY sex",
      %{post_id: post_id}
    )
  end

  def post_views_by_country(post_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      "SELECT country, uniq(user_id) as unique_views FROM post_views WHERE post_id = {post_id} GROUP BY country",
      %{post_id: post_id}
    )
  end

  def post_views_by_city(post_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      "SELECT country, city, uniq(user_id) as unique_views FROM post_views WHERE post_id = {post_id} GROUP BY country, city",
      %{post_id: post_id}
    )
  end

  def post_views_by_age(post_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      """
        WITH histogram(10)(post_views.age) AS hist
        SELECT
          concat(toString(arrayJoin(hist).1), '-', toString(arrayJoin(hist).2)) AS age,
          arrayJoin(hist).3 AS unique_views
        FROM post_views WHERE post_id = {post_id}
      """,
      %{post_id: post_id}
    )
  end

  def post_views_total(post_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      "SELECT count(*) total_views, uniq(user_id) as unique_views FROM post_views WHERE post_id = {post_id}",
      %{post_id: post_id}
    )
  end

  def get_post_stats(post_id) do
    with {:ok, views_by_sex} <- post_views_by_sex(post_id),
         {:ok, views_by_city} <- post_views_by_city(post_id),
         {:ok, [%{"total_views" => total_views, "unique_views" => unique_views}]} <- post_views_total(post_id) do
      {:ok,
        %{
          total_views: total_views,
          unique_views: unique_views,
          views_by_city: views_by_city,
          views_by_sex: views_by_sex
        }}
    end
  end

  def business_views_by_sex(business_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      """
        SELECT sex, uniq(user_id) as unique_views FROM post_views
        WHERE
          post_id IN (SELECT post_id FROM business_posts WHERE business_id = {business_id})
        GROUP BY sex
      """,
      %{business_id: business_id}
    )
  end

  def business_views_by_country(business_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      """
        SELECT country, uniq(user_id) as unique_views FROM post_views
        WHERE
          post_id IN (SELECT post_id FROM business_posts WHERE business_id = {business_id})
        GROUP BY country
      """,
      %{business_id: business_id}
    )
  end

  def business_views_by_city(business_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      """
        SELECT country, city, uniq(user_id) as unique_views FROM post_views
        WHERE
          post_id IN (SELECT post_id FROM business_posts WHERE business_id = {business_id})
        GROUP BY country, city
      """,
      %{business_id: business_id}
    )
  end

  def business_views_by_age(business_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      """
        WITH histogram(10)(post_views.age) AS hist
        SELECT
          concat(toString(arrayJoin(hist).1), '-', toString(arrayJoin(hist).2)) AS age,
          arrayJoin(hist).3 AS unique_views
        FROM post_views
        WHERE
          post_id IN (SELECT post_id FROM business_posts WHERE business_id = {business_id})
      """,
      %{business_id: business_id}
    )
  end

  def business_views_total(business_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      """
        SELECT count(*) total_views, uniq(user_id) as unique_views FROM post_views
        WHERE
          post_id IN (SELECT post_id FROM business_posts WHERE business_id = {business_id})
      """,
      %{business_id: business_id}
    )
  end

  def business_viewed_posts(business_id) do
    Pillar.select(
      BillBored.Clickhouse.conn(),
      "SELECT uniq(post_id) AS count FROM business_posts WHERE business_id = {business_id}",
      %{business_id: business_id}
    )
  end

  def get_business_stats(business_id) do
    with {:ok, views_by_sex} <- business_views_by_sex(business_id),
         {:ok, views_by_city} <- business_views_by_city(business_id),
         {:ok, [%{"total_views" => total_views, "unique_views" => unique_views}]} <- business_views_total(business_id),
         {:ok, [%{"count" => viewed_posts}]} <- business_viewed_posts(business_id) do
      {:ok,
        %{
          total_views: total_views,
          unique_views: unique_views,
          viewed_posts: viewed_posts,
          views_by_city: views_by_city,
          views_by_sex: views_by_sex
        }}
    end
  end

  def post_views(params) do
    params =
      %{precision: 12}
      |> Map.merge(params)
      |> Map.take([:post_id, :business_id, :datetime_from, :datetime_to, :precision, :unique])

    post_id_clause = if params[:post_id] do
      "post_id = {post_id}"
    else
      "post_id IN (SELECT post_id FROM business_posts WHERE business_id = {business_id})"
    end

    viewed_from_clause = if params[:datetime_from] do
      "AND viewed_at >= {datetime_from}"
    else
      ""
    end

    viewed_before_clause = if params[:datetime_to] do
      "AND viewed_at <= {datetime_to}"
    else
      ""
    end

    geohash_clause = if params[:precision] == 12 do
      "post_views.geohash"
    else
      "substring(post_views.geohash, 1, {precision})"
    end

    views_clause = if params[:unique] do
      "uniq(user_id) AS unique_views"
    else
      "count(*) AS total_views"
    end

    sql = """
      SELECT #{geohash_clause} AS geohash, #{views_clause} FROM post_views
      WHERE
        #{post_id_clause}
        #{viewed_from_clause}
        #{viewed_before_clause}
      GROUP BY #{geohash_clause}
    """

    Pillar.select(BillBored.Clickhouse.conn(), sql, params)
  end

  def get_post_views(post_id, accuracy_radius \\ 1_000) do
    precision = BillBored.Geo.Hash.estimate_precision_at(%BillBored.Geo.Point{long: 0, lat: 0}, accuracy_radius)

    with {:ok, views} <- post_views(%{post_id: post_id, precision: precision, unique: true}) do
      location_views =
        views
        |> Enum.map(fn %{"geohash" => geohash, "unique_views" => count} ->
          {lon, lat} = Geohash.decode(geohash)
          %{location: %BillBored.Geo.Point{long: lon, lat: lat}, count: count}
        end)

      {:ok, %{
        precision: precision,
        accuracy_radius: accuracy_radius,
        views: location_views
      }}
    end
  end
end