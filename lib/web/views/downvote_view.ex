defmodule Web.DownvoteView do
  use Web, :view

  alias BillBored.{Post}

  def render("show.json", %{downvote: %Post.Downvote{} = downvote, user_id: user_id}) do
    %{
      id: downvote.id,
      user: render_one(downvote.user, Web.UserView, "min.json", %{user_id: user_id}),
      post: render_one(downvote.post, Web.PostView, "show.json", %{user_id: user_id})
    }
  end

  def render("show.json", %{downvote: %Post.Comment.Downvote{} = downvote, user_id: user_id}) do
    %{
      id: downvote.id,
      user: render_one(downvote.user, Web.UserView, "min.json", %{user_id: user_id}),
      comment: render_one(downvote.comment, Web.PostCommentView, "show.json", %{user_id: user_id})
    }
  end
end
