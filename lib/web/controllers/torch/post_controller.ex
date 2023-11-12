defmodule Web.Torch.PostController do
  use Web, :controller

  alias BillBored.Post
  alias BillBored.Torch.Posts, as: TorchPosts

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    case TorchPosts.paginate_posts(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)
      error ->
        conn
        |> put_flash(:error, "There was an error rendering Posts. #{inspect(error)}")
        |> redirect(to: Routes.torch_post_path(conn, :index))
    end
  end

  def index_for_review(conn, params) do
    case TorchPosts.paginate_posts(params |> Map.merge(%{count_reports: true})) do
      {:ok, assigns} ->
        render(conn, "index_for_review.html", assigns)
      error ->
        conn
        |> put_flash(:error, "There was an error rendering Posts. #{inspect(error)}")
        |> redirect(to: Routes.torch_post_path(conn, :index_for_review))
    end
  end

  def show(conn, %{"id" => id}) do
    post = TorchPosts.get_post!(id, reports_count: true)
    render(conn, "show.html", post: post)
  end

  def delete(conn, %{"id" => id}) do
    post = TorchPosts.get_post!(id)
    {:ok, _post} = TorchPosts.delete_post(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: Routes.torch_post_path(conn, :index))
  end

  def approve_post_review(conn, %{"id" => id}) do
    update_action(conn, id, "approve post", fn ->
      TorchPosts.get_post!(id)
      |> Post.admin_changeset(%{
        hidden?: false,
        last_reviewed_at: DateTime.utc_now(),
        review_status: "accepted"
      })
      |> Repo.update()
    end)
  end

  def reject_post_review(conn, %{"id" => id}) do
    update_action(conn, id, "reject post", fn ->
      TorchPosts.get_post!(id)
      |> Post.admin_changeset(%{
        hidden?: true,
        last_reviewed_at: DateTime.utc_now(),
        review_status: "rejected"
      })
      |> Repo.update()
    end)
  end

  defp update_action(conn, id, action, fun) do
    with {:ok, _} <- fun.() do
      conn
      |> put_flash(:info, "#{action}: success")
      |> redirect(to: Routes.torch_post_path(conn, :show, id))
    else
      error ->
        conn
        |> put_flash(:error, "#{action} failed: #{inspect(error)}")
        |> redirect(to: Routes.torch_post_path(conn, :show, id))
    end
  end
end