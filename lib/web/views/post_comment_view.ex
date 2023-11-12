defmodule Web.PostCommentView do
  use Web, :view

  @fields [
    :id,
    :body,
    :inserted_at,
    :updated_at,
    :disabled?,
    :post_id,
    :parent_id,
    :upvotes_count,
    :downvotes_count,
    :blocked?
  ]

  defp count_children([]), do: 0

  defp count_children(children) do
    length(children) +
      (children
       |> Enum.map(&count_children(&1.children))
       |> Enum.sum())
  end

  def render("index.json", %{conn: conn, comments: comments}) do
    Web.ViewHelpers.index(conn, comments, __MODULE__, "min.json")
  end

  def render("index_tree.json", %{conn: conn, comments: comments}) do
    Web.ViewHelpers.index(conn, comments, __MODULE__, "show.json")
  end

  def render(template, %{post_comment: comment} = assigns) do
    assigns =
      assigns
      |> Map.delete(:post_comment)
      |> Map.put(:comment, comment)

    render(template, assigns)
  end

  def render("min.json", assigns) do
    render("show.json", assigns)
    |> Map.delete(:children)
  end

  def render("show.json", %{comment: comment, user_id: user_id}) do
    json =
      comment
      |> Map.take(@fields)
      |> Map.put(:author, render_one(comment.author, Web.UserView, "min.json"))
      |> Map.put(
        :children,
        render_many(comment.children, Web.PostCommentView, "show.json", %{user_id: user_id})
      )
      |> Map.put(
        # TODO rename to media_files
        :media_file_keys,
        render_many(comment.media_files, Web.MediaView, "show.json")
      )
      |> Map.put(:interests, Enum.map(comment.interests, & &1.hashtag))
      |> Map.put(:user_upvoted?, comment.user_upvoted?)
      |> Map.put(:user_downvoted?, comment.user_downvoted?)

    Map.put(json, :number_of_replies, count_children(json.children))
  end
end
