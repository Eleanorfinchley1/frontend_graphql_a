defmodule Web.PostView do
  use Web, :view

  @fields [
    :id,
    :title,
    :type,
    :body,
    :business_name,
    :downvotes_count,
    :upvotes_count,
    :comments_count,
    :user_upvoted?,
    :user_downvoted?,
    :private?,
    :hidden?,
    :post_cost,
    :approved?,
    :inserted_at,
    :updated_at
  ]

  def render("index.json", %{conn: conn, data: posts}) do
    Web.ViewHelpers.index(conn, posts, __MODULE__, "min.json")
  end

  def render("min.json", %{post: post}) do
    Map.take(post, @fields -- [:private?, :body])
  end

  def render("show.json", %{post: post}) do
    {fake_location?, location} =
      if fake_location = post.fake_location do
        {true, fake_location}
      else
        {false, post.location}
      end

    result =
      post
      |> Map.take(@fields ++ [:parent_id])
      |> Map.put(:location, render_one(location, Web.LocationView, "show.json"))
      |> Map.put(:fake_location?, fake_location?)
      # TODO rename to media_files
      |> Map.put(
        :media_file_keys,
        render_many(
          post.media_files ++ (post.eventbrite_urls || []) ++ (post.eventful_urls || []) ++ (post.provider_urls || []),
          Web.MediaView,
          "show.json"
        )
      )
      |> Map.put(:interests, Enum.map(post.interests, & &1.hashtag))
      |> Map.put(:place, render_one(post.place, Web.PlaceView, "show.json"))
      |> Map.put(:business, render_author(post.business || post.admin_author))
      |> Map.put(:business_admin, render_author(post.business_admin || post.admin_author))
      |> Map.put(:author, render_author(post.author || post.admin_author))
      |> Map.put(:polls, render_many(post.polls, Web.PollView, "show.json"))
      |> Map.put(:events, render_many(post.events, Web.EventView, "show.json"))
      |> Map.put(:universal_link, Web.Helpers.universal_link(post.id, %{schema: BillBored.Post}))
      |> Map.put(:event_provider, post.event_provider || "")

    if post.business_offer do
      Map.put(result, :business_offer, render_one(post.business_offer, Web.BusinessOfferView, "show.json"))
    else
      result
    end
  end

  defp render_author(nil), do: nil

  defp render_author(%BillBored.Admin{} = author) do
    render_one(author, Web.Torch.API.AdminView, "min.json")
  end

  defp render_author(%BillBored.User{} = author) do
    render_one(author, Web.UserView, "min.json")
  end

  defp render_author(author) do
    if Ecto.assoc_loaded?(author) do
      render_author(author)
    else
      nil
    end
  end

  def render("for_marker.json", %{post: post}) do
    {fake_location?, location} =
      if fake_location = post.fake_location do
        {true, fake_location}
      else
        {false, post.location}
      end

    post
    |> Map.take(@fields -- [:private?, :body])
    |> Map.put(:location, render_one(location, Web.LocationView, "show.json"))
    |> Map.put(:fake_location?, fake_location?)
    |> Map.put(:author, render_one(post.author, Web.UserView, "min.json"))
  end

  def render("marker.json", %{marker: %{top_posts: top_posts} = marker}) do
    marker
    |> Map.take(~w(location_geohash precision posts_count)a)
    |> Map.put(:location, render_one(marker[:location], Web.LocationView, "show.json"))
    |> Map.put(:top_posts, render_many(top_posts, Web.PostView, "for_marker.json"))
  end
end
