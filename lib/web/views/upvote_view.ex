defmodule Web.UpvoteView do
  use Web, :view

  alias BillBored.{Post}

  def render("show.json", %{upvote: %Post.Upvote{} = upvote, user_id: user_id}) do
    %{
      id: upvote.id,
      user: render_one(upvote.user, Web.UserView, "min.json", %{user_id: user_id}),
      post: render_one(upvote.post, Web.PostView, "show.json", %{user_id: user_id})
    }
  end

  def render("show.json", %{upvote: %Post.Comment.Upvote{} = upvote, user_id: user_id}) do
    %{
      id: upvote.id,
      user: render_one(upvote.user, Web.UserView, "min.json", %{user_id: user_id}),
      comment: render_one(upvote.comment, Web.PostCommentView, "show.json", %{user_id: user_id})
    }
  end
end
