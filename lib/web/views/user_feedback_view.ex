defmodule Web.UserFeedbackView do
  use Web, :view

  def render("index.json", %{conn: conn, data: entries}) do
    Web.ViewHelpers.index(conn, entries, __MODULE__)
  end

  def render("show.json", %{user_feedback: user_feedback}) do
    %{
      feedback_type: user_feedback.feedback.feedback_type,
      feedback: user_feedback.feedback.message,
      feedback_image: user_feedback.feedback.feedback_image,
      rating: user_feedback.rating,
      user_username: user_feedback.user.username,
      user_email: user_feedback.user.email
    }
  end
end
