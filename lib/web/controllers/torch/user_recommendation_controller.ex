defmodule Web.Torch.UserRecommendationController do
  use Web, :controller

  alias BillBored.Torch.UserRecommendations

  plug(:put_layout, {Web.LayoutView, "torch.html"})

  def index(conn, params) do
    case UserRecommendations.paginate(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering user recommendations: #{inspect(error)}")
        |> redirect(to: Routes.torch_user_recommendation_path(conn, :index))
    end
  end

  def create(conn, %{"user_recommendation" => attrs} = params) do
    with {:ok, _user_recommendation} <- UserRecommendations.create(attrs) do
      conn
      |> put_flash(:info, "User recommendation created")
      |> redirect(to: params["return_url"] || Routes.torch_user_recommendation_path(conn, :index))
    else
      error ->
        conn
        |> put_flash(:error, "Failed to create user recommendation: #{inspect(error)}")
        |> redirect(to: params["return_url"] || Routes.torch_user_recommendation_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id}) do
    user_recommendation = UserRecommendations.get!(id)
    with {:ok, _user_recommendation} <- UserRecommendations.delete(user_recommendation) do
      conn
      |> put_flash(:info, "User recommendation #{id} deleted successfully.")
      |> redirect(to: Routes.torch_user_recommendation_path(conn, :index))
    else
      error ->
        conn
        |> put_flash(:error, "Failed to delete user recommendation entry #{id}: #{inspect(error)}")
        |> redirect(to: Routes.torch_user_recommendation_path(conn, :index))
    end
  end
end
