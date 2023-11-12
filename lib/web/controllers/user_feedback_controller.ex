defmodule Web.UserFeedbackController do
  use Web, :controller
  alias BillBored.Users

  action_fallback Web.FallbackController

  def action(%Plug.Conn{params: params, assigns: %{user_id: user_id}} = conn, _opts) do
    apply(__MODULE__, action_name(conn), [conn, params, user_id])
  end

  def index(conn, params, _opts) do
    render(conn, "index.json", data: Users.index_user_feedbacks(params))
  end

  def show(conn, %{"id" => id}, _opts) do
    feedback =
      Users.get_user_feedback!(feedback_ptr_id: id)
      |> Repo.preload([:feedback, :user])

    render(conn, "show.json", %{user_feedback: feedback})
  end

  def create(conn, params, _opts) do
    params = Map.put(params, "user_id", conn.assigns.user_id)

    case Users.create_user_feedback(params) do
      {:ok, user_feedback} ->
        feedback = Repo.preload(user_feedback, [:feedback, :user])
        render(conn, "show.json", user_feedback: feedback)

      {:error, _reason} ->
        # TODO why 404 and not 412?
        send_resp(conn, 404, [])
    end
  end

  def update(conn, %{"id" => id} = params, _opts) do
    case Users.create_or_update_user_feedback(id, params) do
      {:ok, user_feedback} ->
        feedback = Repo.preload(user_feedback, [:feedback, :user])
        render(conn, "show.json", user_feedback: feedback)

      {:error, _} ->
        # TODO why 404 and not 412?
        send_resp(conn, 404, [])
    end
  end

  def delete(conn, %{"id" => id}, _opts) do
    user_feedback = Users.get_user_feedback!(feedback_ptr_id: id)
    Users.delete_user_feedback!(user_feedback)
    send_resp(conn, 204, [])
  end
end
